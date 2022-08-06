import os
from threading import Thread
from concurrent.futures import ThreadPoolExecutor

from test_function import s3_getter
from os_level_monitor.monitor import Monitor


def main():
    with ThreadPoolExecutor() as executor:
        monitor = Monitor()
        monitor_future = executor.submit(monitor.monitor_resources)
        fnc_future = executor.submit(s3_getter.run)

        fnc_future.result()
        monitor.continoue = False
        resource_usage = monitor_future.result()


if __name__ == "__main__":
    main()
