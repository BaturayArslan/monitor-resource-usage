
# monitor-resource-usage

Bunch of tools and code snippets that help you measure resource usage of your python program from outside of your python interpreter process (os-level) or inside interpreter process.


## Usage/Examples
#### OS LEVEL MONITOR ####

* this shell script run your code in subprocess while running your code monitor resource usage by your process and children of it and produce report.


```bash
monitor.sh "python3 path/to/your/code"
```
![report-wtih-text](https://user-images.githubusercontent.com/33760107/184515431-63629cb7-71fb-4f12-bf34-9dde49d9ad25.png)
![memory-sample](https://user-images.githubusercontent.com/33760107/184515436-46440385-b155-4c92-8efe-ee52b6519a1c.png)


#### With Python Resource Module ####

* Place your program entry point to entry.py and set up resource module parameter as your need.
