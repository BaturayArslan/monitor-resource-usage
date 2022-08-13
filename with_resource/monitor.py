import resource

from time import sleep

class MemoryMonitor:
    def __init__(self):
        self.continoue = True

    def monitor_resources(self):
        max_usage = 0
        while self.keep_measuring:
            max_usage = max(
                max_usage,
                resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
            )
            sleep(0.1)

        return max_usage