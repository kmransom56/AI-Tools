#!/usr/bin/env python
"""
AI Toolkit Development Server Launcher
Quick startup script for local development testing
"""
import os
import sys
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    # Check environment
    logger.info("Checking AI Toolkit setup...")
    
    # Check Python version
    if sys.version_info < (3, 8):
        logger.error("Python 3.8+ required")
        sys.exit(1)
    logger.info(f"✓ Python {sys.version_info.major}.{sys.version_info.minor} detected")
    
    # Check .env file
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_file):
        logger.info(f"✓ .env file found at {env_file}")
        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv(env_file)
        logger.info("✓ Environment variables loaded")
    else:
        logger.warning(f".env file not found at {env_file}")
        logger.warning("API keys will not be available unless set in system environment")
    
    # Check templates
    templates_dir = os.path.join(os.path.dirname(__file__), 'templates')
    if os.path.exists(templates_dir):
        logger.info(f"✓ Templates directory found: {templates_dir}")
    else:
        logger.error(f"✗ Templates directory not found: {templates_dir}")
        sys.exit(1)
    
    # Try importing the app
    try:
        logger.info("Importing AI Toolkit application...")
        import ai_web_app
        logger.info(f"✓ App imported successfully: {ai_web_app.app.title}")
    except Exception as e:
        logger.error(f"✗ Failed to import app: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Start the server
    logger.info("=" * 70)
    logger.info("Starting AI Toolkit Web Interface...")
    logger.info("=" * 70)
    logger.info("Access the web interface at: http://localhost:8000")
    logger.info("API documentation at: http://localhost:8000/docs")
    logger.info("Press Ctrl+C to stop the server")
    logger.info("=" * 70)
    
    try:
        import uvicorn
        uvicorn.run(
            "ai_web_app:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Server error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
