import os
from threading import Thread
from concurrent.futures import ThreadPoolExecutor

from with_resource import monitor
from test_function import s3_getter

def main():
    with ThreadPoolExecutor() as executor:
        monitor_ = monitor.MemoryMonitor()
        monitor_future = executor.submit(monitor_.monitor_resources)
        fnc_future = executor.submit(s3_getter.run)

        fnc_future.result()
        monitor.continoue = False
        resource_usage = monitor_future.result()
        print(f"result :: {resource_usage}",flush=True)


if __name__ == "__main__":
    main()
