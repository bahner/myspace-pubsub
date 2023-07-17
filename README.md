# Libp2p pubsub for Elixir

This module provides messaging between actors
somewhere else. It's intended to be used between
Elixir applications as a means to send messages
to be picked up by foreign BEAM processes.

In a perfect world this type of messaging could
be implemented in the underlying language itself,
but we are not quite there yet.

## KISS

This module is a bit like the libp2p module.
That uses the go-libp2p daemon as backend, however,
and the developers recommend against using it.

This is a more limited module, with it's own backend
daemon, which is only used for rendezvous pubsub.

PubSub for libp2p is a fast moving target and it's
being removed from IPFS itself. Hence I have created
one for what I need.

This module will help you send messages between
elixir modules all over the world in partnership
with the backend daemon. That's what it's written
for. For extensive libp2p development and
experimentation this module is not for you.
