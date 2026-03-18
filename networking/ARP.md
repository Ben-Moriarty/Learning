What is?
Address Resolution Protocol. A protocol to resolve communication between layer 2 and layer 3. If a layer 3 device wants to communicate with another layer 3 device, it will need to send a layer 2 ethernet frame. However,
if the sender does not know the MAC of the receiver, this frame cannot be created. This is resolved by making an ARP broadcast request. The receiver will see this request and respond with a unicast message containing its MAC
to the sender. The sender caches the receiver's MAC in an ARP table for efficient retrieval.
