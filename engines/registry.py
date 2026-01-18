"""Engine Registry for AI-Tools"""

from pathlib import Path
from typing import Dict, Type, Any

# Import backends
try:
    from engines.powerinfer.backend import PowerInferBackend
    POWERINFER_AVAILABLE = True
except ImportError:
    POWERINFER_AVAILABLE = False

# Engine registry
ENGINES: Dict[str, Type] = {}

if POWERINFER_AVAILABLE:
    ENGINES["powerinfer"] = PowerInferBackend

# Add other engines here as they become available
# ENGINES["llama_cpp"] = LlamaCppBackend
# ENGINES["vllm"] = VLLMBackend


def get_engine(name: str, repo_root: Path) -> Any:
    """Get engine backend by name
    
    Args:
        name: Engine name (e.g., 'powerinfer')
        repo_root: Path to repository root
        
    Returns:
        Engine backend instance
        
    Raises:
        ValueError: If engine name is unknown
    """
    if name not in ENGINES:
        available = list(ENGINES.keys()) if ENGINES else ["none"]
        raise ValueError(
            f"Unknown engine: {name}. Available engines: {available}"
        )
    
    return ENGINES[name](repo_root)


def list_engines() -> list[str]:
    """List available engines"""
    return list(ENGINES.keys())
