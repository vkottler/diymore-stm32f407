target remote localhost:2331
monitor reset
monitor SWO EnableTarget 0 0 1 0
break main
continue
