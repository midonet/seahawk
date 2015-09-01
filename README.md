# seahawk
You have to git clone this repository to the box where you have been running packstack.

Then you need to modify the file conf/gateways.txt and enter the ips of where you want to run the midonet gateways.

This can be ips of compute nodes, even the controller, we do not care.

This script expects the answerfile in /root/answers.txt.

If its not there or you are using a different filename you can export the environment variable ANSWERFILE to point to it.

WARNING: this script will only work AFTER you have been running packstack.

WARNING: You must run this script on the machine where you have been running packstack because we need to access the packstack file.

WARNING: Most likely you will run the script on the controller node. We will learn the compute nodes from the answerfile.

You need at least two compute nodes.

We will install the NSDB (zookeeper and cassandra) on the controller and the first two compute nodes.

