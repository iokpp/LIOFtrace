LIO (Linux I/O key performance parameter) front-end Tools
============
Free use of this software is granted under the terms of the GNU Public License (GPL).

LIO (Linux IO key performance parameter) is a Linux storage subsystem timing analysis tool, which provides a non-invasive method to collect timing data on the path from user space to storage devices on the Linux storage subsystem. It consists of front-end tools and back-end (parser) tools. This tool is a preliminary front-end part that runs on the target machine and is used to install/enable trace events, trigger Linux I/O request events, and collect trace event logs. This Git Repo includes a set of front-end tools for LIO. Each tool can be used independently according to the specific platform environment and dependencies. 

The back-end tool runs on the server side, which is used to analyze/parse the log of LIO front-end tool, and provide the I/O performance timing statistics. The preliminary version of back-end tool is based on the command line interface.

---

Dependencies
============
v.0.1.  At the initial version, this front-end tool is based on the ftrace
 * ftrace


---
Usage
============

    ./LIOFtrace-c.sh [-o <file>] [-O flag] [-c "command"] ...

        -o <file> : Trace log location  

        -p <tracer> : Which tracer do you want to deploy.  
        
        -O <flag string> : Add new command option parameters for trace log.  
        
        -m <buffer size in byte> : Set the trace buffer size per cpu.  
        
        -c "command" : The running command while tracing. Use -c before command if
                       using command options that could be confused with options.
                       If this option is not specified, tool will go into "monitor" mode.  
        
        -h|-H : Show usage infor.  

    eg:  
            ./LIOFtrace-c.sh -o ./trace.log -O nooverwrite -m 65536 -c "/data/iozone -eco ..."

----
        
FIXME list
============
 * None


Developers
============
 Bean Huo <beanhuo@micron.com>

