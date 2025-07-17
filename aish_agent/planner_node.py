"""
Planner node for LangGraph agent.
Uses LLM to break natural language instructions into actionable steps.
"""

import json
from typing import Dict, List, Any
from langchain_openai import ChatOpenAI
from langchain_community.llms import Ollama
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from .config import get_config

class PlannerNode:
    """LangGraph node that plans tasks from natural language input."""
    
    def __init__(self):
        """Initialize the planner node."""
        self.config = get_config()
        self.llm_config = self.config.get_llm_config()
        self.llm = self._create_llm()
        
        # System prompt for planning
        self.system_prompt = """You are an expert system administrator and DevOps engineer. Your job is to break down natural language instructions into clear, actionable steps that can be executed as shell commands.

For each user request, analyze what needs to be done and create a step-by-step plan. Each step should be:
1. Clear and specific
2. Executable as a shell command
3. Safe and follow best practices
4. Ordered logically (dependencies first)

Return your response as a JSON object with the following structure:
{
    "plan": [
        {
            "step": 1,
            "description": "Brief description of what this step does",
            "task": "Detailed task description",
            "category": "install|configure|start|stop|check|create|delete|update|other"
        }
    ],
    "summary": "Brief summary of the overall plan",
    "estimated_time": "Estimated time to complete (e.g., '2-3 minutes')",
    "requires_sudo": true/false,
    "warnings": ["Any warnings or considerations"]
}

Examples:

User: "install nginx and start the service"
Response:
{
    "plan": [
        {
            "step": 1,
            "description": "Update package manager",
            "task": "Update the package manager to ensure we have the latest package information",
            "category": "update"
        },
        {
            "step": 2,
            "description": "Install nginx",
            "task": "Install the nginx web server package",
            "category": "install"
        },
        {
            "step": 3,
            "description": "Start nginx service",
            "task": "Start the nginx service and enable it to start on boot",
            "category": "start"
        },
        {
            "step": 4,
            "description": "Check nginx status",
            "task": "Verify that nginx is running correctly",
            "category": "check"
        }
    ],
    "summary": "Install nginx web server and start the service",
    "estimated_time": "2-3 minutes",
    "requires_sudo": true,
    "warnings": ["This will install nginx system-wide", "Nginx will be accessible on port 80"]
}

User: "show me all running processes"
Response:
{
    "plan": [
        {
            "step": 1,
            "description": "List all running processes",
            "task": "Display all currently running processes with detailed information",
            "category": "check"
        }
    ],
    "summary": "Display all running processes",
    "estimated_time": "< 1 minute",
    "requires_sudo": false,
    "warnings": []
}

Be thorough but concise. Focus on practical, executable steps."""
    
    def _create_llm(self):
        """Create LLM instance based on configuration."""
        if self.llm_config['type'] == 'openai':
            return ChatOpenAI(
                api_key=self.llm_config['api_key'],
                model=self.llm_config['model'],
                temperature=0.1,
                timeout=self.llm_config['timeout']
            )
        elif self.llm_config['type'] == 'ollama':
            return Ollama(
                model=self.llm_config['model'],
                base_url=self.llm_config['base_url'],
                temperature=0.1
            )
        else:
            raise ValueError(f"Unsupported LLM type: {self.llm_config['type']}")
    
    def _parse_response(self, response: str) -> Dict[str, Any]:
        """
        Parse LLM response and extract plan.
        
        Args:
            response: Raw LLM response
            
        Returns:
            Parsed plan dictionary
        """
        try:
            # Try to parse as JSON
            if response.strip().startswith('{'):
                return json.loads(response)
            
            # If not JSON, try to extract JSON from response
            start_idx = response.find('{')
            end_idx = response.rfind('}') + 1
            
            if start_idx != -1 and end_idx != -1:
                json_str = response[start_idx:end_idx]
                return json.loads(json_str)
            
            # If no JSON found, create a basic plan
            return {
                "plan": [
                    {
                        "step": 1,
                        "description": "Execute user request",
                        "task": response.strip(),
                        "category": "other"
                    }
                ],
                "summary": "Execute user request",
                "estimated_time": "Unknown",
                "requires_sudo": False,
                "warnings": ["Could not parse detailed plan"]
            }
            
        except json.JSONDecodeError as e:
            if self.config.debug:
                print(f"Debug: JSON parse error: {e}")
                print(f"Debug: Response: {response}")
            
            # Fallback to basic plan
            return {
                "plan": [
                    {
                        "step": 1,
                        "description": "Execute user request",
                        "task": response.strip(),
                        "category": "other"
                    }
                ],
                "summary": "Execute user request",
                "estimated_time": "Unknown",
                "requires_sudo": False,
                "warnings": ["Could not parse LLM response"]
            }
    
    def plan(self, user_input: str) -> Dict[str, Any]:
        """
        Create a plan from natural language input.
        
        Args:
            user_input: Natural language instruction
            
        Returns:
            Plan dictionary with steps and metadata
        """
        try:
            # Create prompt
            messages = [
                SystemMessage(content=self.system_prompt),
                HumanMessage(content=user_input)
            ]
            
            # Get LLM response
            if self.config.debug:
                print(f"Debug: Sending to LLM: {user_input}")
            
            response = self.llm.invoke(messages)
            
            # Extract content based on LLM type
            if hasattr(response, 'content'):
                content = response.content
            else:
                content = str(response)
            
            if self.config.debug:
                print(f"Debug: LLM response: {content}")
            
            # Parse response
            plan = self._parse_response(content)
            
            # Validate plan structure
            if not isinstance(plan.get('plan'), list):
                raise ValueError("Plan must contain a list of steps")
            
            # Ensure all steps have required fields
            for step in plan['plan']:
                if not all(key in step for key in ['step', 'description', 'task', 'category']):
                    raise ValueError("Each step must have step, description, task, and category fields")
            
            return plan
            
        except Exception as e:
            if self.config.debug:
                print(f"Debug: Planning error: {e}")
            
            # Return fallback plan
            return {
                "plan": [
                    {
                        "step": 1,
                        "description": "Execute user request",
                        "task": user_input,
                        "category": "other"
                    }
                ],
                "summary": "Execute user request (fallback plan)",
                "estimated_time": "Unknown",
                "requires_sudo": False,
                "warnings": [f"Planning failed: {str(e)}"]
            }
    
    def __call__(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        LangGraph node entry point.
        
        Args:
            state: Current graph state
            
        Returns:
            Updated state with plan
        """
        user_input = state.get('user_input', '')
        
        if not user_input:
            return {
                **state,
                'plan': {
                    "plan": [],
                    "summary": "No input provided",
                    "estimated_time": "0 minutes",
                    "requires_sudo": False,
                    "warnings": ["No user input provided"]
                }
            }
        
        # Generate plan
        plan = self.plan(user_input)
        
        # Update state
        return {
            **state,
            'plan': plan,
            'current_step': 0,
            'completed_steps': [],
            'failed_steps': []
        } 