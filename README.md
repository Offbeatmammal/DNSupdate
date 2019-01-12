# DNSUpdate

A PowerShell script to update various services when my home IP address changes

Why does this exist?
--------------------
As with many residential ISPs I am unable to get a fixed IP address for my service, which can be frustrating if the IP address changes (eg as a result of a power outage). 

In my particular scenario I needed to update a [CloudFlare](https://cloudflare.com) hosted DNS for the endpoint I use for my VPN, and also update the entry for my [SmartDNSProxy](https://SmartDNSProxy.com) service so the machines using that only had minimal interruption.

As I have a Windows machine that's always-on, it seemed like a good exercise to do with PowerShell, though easy enough to switch to bash if I want to move it to the Raspberry-PI that's used for some other things at home.

How to use
----------

To use the script you simply replace your CloudFlare domain details and [API keys](https://api.cloudflare.com/) (email address and token), and the [SmartDNSProxy API key](https://www.smartdnsproxy.com/Developers) and run it as often as you need.

The script queries [myexternalip.com](http://myexternalip.com) to get your public IP address (I've found this to be a very reliable, consistant source), and if the IP address differs from the one that CloudFlare thinks your entry is referencing it updates both CloudFlare and SmartDNSProxy with the new one (and updates the log file).

I have a Windows Task Scheduler event set to run the script every 5 minutes which, for my purposes, is adequate.


To Do
----------
* Improve error trapping
* Optimize code

----------
If you make use of this and like it and want to give something back... [I wrote a book!](http://author.obm.one) :)

----------

Contribute
----------
This project can be forked from
[Github](https://github.com/Offbeatmammal/DNSupdate). Please issue pull
requests from feature branches.

License
-------
See Licence file in repo, or refer to http://unlicense.org