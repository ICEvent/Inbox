WEB3 INBOX
====================
Own your server to own your data.
one inbox hooks to multiple dapps

---------     ---------     --------- 
| user  | ==> | carrier |  => | inbox-1 |      
---------     ---------     ---------
                  |
                 \/ 
              -----------
              | inbox-n |
              -----------

1. create a canister (https://nns.ic0.app/)

2. deploy Inbox module to the created canister
   - git clone git@github.com:ICEvent/Inbox.git
   - dfx deploy --network ic inbox_backend --argument "InboxName"
   - (upgrade) dfx canister --network ic install inbox_backend --mode upgrade --argument "InboxName"


3. register canister on carrier (e.g. icevent.app/inbox ...)

4. send messages to registed name through carrier dapp

(carrier) integration - call drop method to send message to inbox