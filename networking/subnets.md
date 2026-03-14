What is?
A subnet allows devices to be divided into smaller networks inside a larger network. These smaller networks use routers to communicate with the larger network.

Why?
Subnets allow for many devices to be on the same large network, but prevent congestion from broadcast messages being sent to ALL devices on that network. The broadcast message is only sent to devices in a subnet.

How?
The first x bits are reserved for a specific subnet. If 192.168.0 are the reserved bits then every device beginning with 192.168.0 is in the same subnet. CIDR notation /24 = first 24 bits are reserved.

The useable addresses of a subnet are 2^n - 2 where n is the non-reserved bits. /24 = 24 reserved bits (32 bits in an address) 32-24 = 8. Usable addresses = 2^8 - 2 = 254. The 2 addresses that are reserved are: the network address and broadcast address.
