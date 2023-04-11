WEB3 INBOX
====================
Own your server to own your data.
one inbox to multiple dapps

---------     ---------     --------- 
| user  | ==> | proxy |  => | inbox-1 |      
---------     ---------     ---------
                  |
                 \/ 
              -----------
              | inbox-n |
              -----------

1. create a canister (https://nns.ic0.app/)
2. deploy Inbox to the created canister
3. register canister on client/proxy (e.g. icevent.app)
4. send message to registed name