"""PowerInfer Backend Implementation for AI-Tools"""

import subprocess
import json
import time
import hashlib
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)


@dataclass
class GenerationMetrics:
    """Metrics for a generation request"""
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    duration_seconds: float
    tokens_per_second: float
    gpu_memory_mb: Optional[float] = None
    cpu_percent: Optional[float] = None


class PowerInferBackend:
    """PowerInfer engine backend with policy-based configuration"""
    
    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root)
        self.binary = self._find_binary()
        self.server_binary = self._find_server_binary()
        logger.info(f"PowerInfer backend initialized: {self.binary}")
        
    def _find_binary(self) -> Path:
        """Locate PowerInfer main binary"""
        # Windows
        win_path = self.repo_root / "build" / "powerinfer" / "bin" / "Release" / "main.exe"
        if win_path.exists():
            return win_path
            
        # Linux/Mac
        unix_path = self.repo_root / "build" / "powerinfer" / "bin" / "main"
        if unix_path.exists():
            return unix_path
            
        # Fallback to PowerInfer subdirectory
        alt_win = self.repo_root / "PowerInfer" / "build" / "bin" / "Release" / "main.exe"
        if alt_win.exists():
            return alt_win
            
        alt_unix = self.repo_root / "PowerInfer" / "build" / "bin" / "main"
        if alt_unix.exists():
            return alt_unix
            
        raise FileNotFoundError(
            "PowerInfer binary not found. Run build script first.\n"
            f"Searched: {win_path}, {unix_path}, {alt_win}, {alt_unix}"
        )
    
    def _find_server_binary(self) -> Path:
        """Locate PowerInfer server binary"""
        # Windows
        win_path = self.repo_root / "build" / "powerinfer" / "bin" / "Release" / "server.exe"
        if win_path.exists():
            return win_path
            
        # Linux/Mac
        unix_path = self.repo_root / "build" / "powerinfer" / "bin" / "server"
        if unix_path.exists():
            return unix_path
            
        # Fallback
        alt_win = self.repo_root / "PowerInfer" / "build" / "bin" / "Release" / "server.exe"
        if alt_win.exists():
            return alt_win
            
        alt_unix = self.repo_root / "PowerInfer" / "build" / "bin" / "server"
        if alt_unix.exists():
            return alt_unix
            
        raise FileNotFoundError("PowerInfer server binary not found.")
    
    def _build_cmd(
        self,
        model_path: Path,
        prompt: str,
        policy: Dict[str, Any],
    ) -> List[str]:
        """Build command line arguments from policy"""
        gen = policy.get("generation", {})
        rt = policy.get("runtime", {})
        
        cmd = [
            str(self.binary),
            "-m", str(model_path),
            "-p", prompt,
            "-n", str(gen.get("max_tokens", 256)),
            "-t", str(rt.get("threads", 8)),
        ]
        
        # GPU layers (optional)
        if "gpu_layers" in rt:
            cmd += ["--gpu-layers", str(rt["gpu_layers"])]
        
        # VRAM budget
        if "vram_budget_gb" in rt:
            cmd += ["--vram-budget", str(rt["vram_budget_gb"])]
        
        # Temperature
        if "temperature" in gen:
            cmd += ["--temp", str(gen["temperature"])]
        
        # Top-p sampling
        if "top_p" in gen:
            cmd += ["--top-p", str(gen["top_p"])]
        
        # Top-k sampling
        if "top_k" in gen:
            cmd += ["--top-k", str(gen["top_k"])]
        
        # Batch size
        if "batch_size" in rt:
            cmd += ["-b", str(rt["batch_size"])]
        
        # Context size
        if "context_size" in rt:
            cmd += ["-c", str(rt["context_size"])]
        
        return cmd
    
    def generate(
        self,
        prompt: str,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
    ) -> str:
        """Generate text using PowerInfer"""
        if model_root is None:
            model_root = self.repo_root
        
        # Resolve model path
        model_path = model_root / policy["model_path"]
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")
        
        # Build command
        cmd = self._build_cmd(model_path, prompt, policy)
        
        logger.info(f"Running PowerInfer: {' '.join(cmd)}")
        
        # Execute
        try:
            proc = subprocess.run(
                cmd,
                check=True,
                capture_output=True,
                text=True,
                timeout=policy.get("runtime", {}).get("timeout", 300),
            )
            return proc.stdout
        except subprocess.TimeoutExpired:
            logger.error("PowerInfer generation timed out")
            raise
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerInfer failed: {e.stderr}")
            raise
    
    def generate_with_metrics(
        self,
        prompt: str,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
    ) -> Tuple[str, GenerationMetrics]:
        """Generate with performance metrics"""
        start_time = time.time()
        
        # Run generation
        output = self.generate(prompt, policy, model_root)
        
        duration = time.time() - start_time
        
        # Calculate metrics (simplified token counting)
        prompt_tokens = len(prompt.split())
        completion_tokens = len(output.split())
        total_tokens = prompt_tokens + completion_tokens
        
        metrics = GenerationMetrics(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
            duration_seconds=duration,
            tokens_per_second=completion_tokens / duration if duration > 0 else 0,
        )
        
        logger.info(
            f"Generation complete: {metrics.tokens_per_second:.2f} tokens/s, "
            f"{metrics.duration_seconds:.2f}s"
        )
        
        return output, metrics
    
    def start_server(
        self,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
        host: str = "0.0.0.0",
        port: int = 8081,
    ) -> subprocess.Popen:
        """Start PowerInfer API server"""
        if model_root is None:
            model_root = self.repo_root
        
        model_path = model_root / policy["model_path"]
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")
        
        rt = policy.get("runtime", {})
        
        cmd = [
            str(self.server_binary),
            "-m", str(model_path),
            "--host", host,
            "--port", str(port),
            "-t", str(rt.get("threads", 8)),
            "--vram-budget", str(rt.get("vram_budget_gb", 10)),
            "-c", str(rt.get("context_size", 2048)),
        ]
        
        logger.info(f"Starting PowerInfer server: {' '.join(cmd)}")
        
        return subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    
    def validate_model(self, model_path: Path, policy: Dict[str, Any]) -> bool:
        """Validate model file and policy"""
        # Check file exists
        if not model_path.exists():
            logger.error(f"Model file not found: {model_path}")
            return False
        
        # Check file size
        size_mb = model_path.stat().st_size / (1024 * 1024)
        logger.info(f"Model size: {size_mb:.2f} MB")
        
        # Validate checksum if provided
        audit = policy.get("audit", {})
        if "checksum" in audit:
            expected = audit["checksum"]
            if expected.startswith("sha256:"):
                expected = expected[7:]
                actual = self._compute_sha256(model_path)
                if actual != expected:
                    logger.error(f"Checksum mismatch: expected {expected}, got {actual}")
                    return False
                logger.info("Checksum validated successfully")
        
        return True
    
    def _compute_sha256(self, file_path: Path) -> str:
        """Compute SHA256 hash of file"""
        sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256.update(chunk)
        return sha256.hexdigest()
    
    def info(self) -> Dict[str, Any]:
        """Get engine information"""
        return {
            "engine": "powerinfer",
            "binary": str(self.binary),
            "server_binary": str(self.server_binary),
            "version": self._get_version(),
        }
    
    def _get_version(self) -> str:
        """Get PowerInfer version"""
        try:
            proc = subprocess.run(
                [str(self.binary), "--version"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            return proc.stdout.strip()
        except:
            return "unknown"
