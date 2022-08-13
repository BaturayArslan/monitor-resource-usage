
# monitor-resource-usage

Bunch of tools and code snippets that help you measure resource usage of your python program from outside of your python interpreter process (os-level) or inside interpreter process.


## Usage/Examples
#### OS LEVEL MONITOR ####

* this shell script run your code in subprocess while running your code monitor resource usage by your process and children of it and produce report.


```bash
monitor.sh "python3 path/to/your/code"
```
![report-wtih-text](https://user-images.githubusercontent.com/33760107/184515452-28156768-bc0f-4928-aeed-8a529a0bf746.png)
![memory-sample](https://user-images.githubusercontent.com/33760107/184515455-6489656f-1265-4153-9562-88b051aa145a.png)


#### With Python Resource Module ####

* Place your program entry point to entry.py and set up resource module parameter as your need.
