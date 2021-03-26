
# SILVER Flow

This file describes the design flow for running the 
[SILVER](https://github.com/Chair-for-Security-Engineering/SILVER) side channel
verification tool.

---

## Getting started

Download and build the SILVER tool. The fork available
[here](https://github.com/ben-marshall/SILVER)
must be used, since it allows for proper passing of command line
arguments.

Having done that, set the `SILVER` environment variable to the
path of the SILVER repository

```
$> export SILVER=<path/to/silver>
```

You will also need to setup the load library path as follows

```
$> export LD_LIBRARY_PATH=$SILVER/lib:$LD_LIBRARY_PATH
$> export LD_LIBRARY_PATH=$BOOST/lib:$LD_LIBRARY_PATH
```

This makes sure the SILVER executable can locate the dependent
BOOST and `libsylvan.so` libraries.
