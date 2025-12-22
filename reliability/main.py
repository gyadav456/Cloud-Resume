import time
import requests
import random
import os
import logging

# Configuration
TARGET_URL = os.environ.get("TARGET_URL", "http://cloud-resume-backend:8000")
INTERVAL = float(os.environ.get("INTERVAL", "1.0")) # Seconds between requests
FAILURE_RATE_THRESHOLD = 0.001 # 0.1% matches our 99.9% SLO

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ReliabilityAgent:
    def __init__(self):
        self.total_requests = 0
        self.failed_requests = 0
        self.latency_sum = 0

    def run(self):
        logger.info(f"Starting Reliability Agent targeting {TARGET_URL}")
        while True:
            self.send_traffic()
            self.validate_slo()
            time.sleep(INTERVAL)

    def send_traffic(self):
        self.total_requests += 1 # Count every attempt
        try:
            start_time = time.time()
            
            # Simulate User Behavior (90% View, 10% Download)
            action = "view"
            if random.random() < 0.1:
                action = "download"

            payload = {"action": action}
            
            # Request to Backend
            response = requests.post(f"{TARGET_URL}/visitor", json=payload, timeout=2)
            
            duration = time.time() - start_time
            self.latency_sum += duration

            if response.status_code == 200:
                logger.debug(f"Success: {action} in {duration:.4f}s")
            else:
                self.failed_requests += 1
                logger.error(f"Failed: Status {response.status_code}")

        except Exception as e:
            self.failed_requests += 1
            logger.error(f"Connection Failed: {str(e)}")

    def validate_slo(self):
        if self.total_requests > 0 and self.total_requests % 10 == 0: # Check every 10 requests, safe divide
            error_rate = self.failed_requests / self.total_requests
            avg_latency = 0
            # Latency sum might be for fewer requests if some failed connection entirely (no duration)
            # But roughly:
            if self.total_requests > self.failed_requests:
                 avg_latency = self.latency_sum / (self.total_requests - self.failed_requests)
            
            status = "PASS"
            if error_rate > FAILURE_RATE_THRESHOLD:
                status = "SLO BREACH"
            
            logger.info(f"SLO Status: {status} | Error Rate: {error_rate:.2%} | Avg Latency: {avg_latency:.4f}s")

if __name__ == "__main__":
    agent = ReliabilityAgent()
    agent.run()
