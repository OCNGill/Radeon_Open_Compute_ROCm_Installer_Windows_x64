import logging
from datetime import datetime
from pathlib import Path

def setup_logger():
    """Configure logging for the installer"""
    log_dir = Path(__file__).parent.parent.parent / "logs"
    log_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"install_{timestamp}.log"
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    
    return logging.getLogger("rocm_installer")

def log_system_info():
    """Log system information at the start of installation"""
    logger = logging.getLogger("rocm_installer")
    
    import platform
    import sys
    
    logger.info("=== System Information ===")
    logger.info(f"OS: {platform.system()} {platform.release()}")
    logger.info(f"Python Version: {sys.version}")
    logger.info(f"Machine: {platform.machine()}")
    logger.info("=========================")