### WEEK 1 (Nov 10-14)

- Bernardini, Giorgio:
I have worked on F3 and F5 creating the multi stage dockerfiles and the docker-compose
https://github.com/doda25-team24/app/pull/1
dockerfile for app, 2 stages (build and runtime). 
https://github.com/doda25-team24/app/pull/2
cleaner version with a better base image

https://github.com/doda25-team24/model-service/pull/2/commits/173f35c5de944cc97984a4efedb6b9de4c6ca0fd
dockerfile for model-service, 2 stages. The container still contains the hard-coded model

https://github.com/doda25-team24/operation/pull/1
docker-compose to put everything together. No volumes are mounted yet.

With the use of Gemini and/or ChatGPT I understood the syntax of the dockerfile for the two stages, wrote them with the help of generative AI, fixed some bugs in docker-compose. Had also some problems finding the right images to use in the dockerfiles.

- Ibanez, Elena:

Completed F6: (model-service) 192444afaae332561d0722d596090bf0158ce9e2 and (app) 49b0f25270370b6ae016a04df83a129739e761cf
Completed F7: https://github.com/doda25-team24/operation/pull/4

- Mititelu, Alexandru:
I have worked on F2, F8 and F11. Here's the pull requests:
### F2 and F11: Versioning & Release Automation
https://github.com/doda25-team24/lib-version/commit/cf2520c17259c2e55559630ebb7f62e8cfacd02c

### F8: Multi-Service
https://github.com/doda25-team24/app/compare/asm/f8?expand=1

https://github.com/doda25-team24/model-service/compare/asm/f8?expand=1

### F4 - Multi-architecture Containers:
https://github.com/doda25-team24/app/pull/4

https://github.com/doda25-team24/model-service/pull/5

- Mundala, Wojciech: https://github.com/doda25-team24/lib-version/compare/5d733155620422db55e75119866e4d3c082eb173...0bcd51d75c58fdd363f1ffeb625caa8779f7c4a5
  Completed features F1 and F2 from Assignment 1. Created versionUtil which can be asked for the library version. Created an automated github workflow to package and rversion 'lib-version'

- de Oliveira Cortez, Sara:

I have worked on A1 F9 and F10, workflows and making the code model independent through envIronment variables.

https://github.com/doda25-team24/model-service/pull/2

https://github.com/doda25-team24/model-service/pull/3

### WEEK 2 (Nov 10-14)

- Mundala, Wojciech
I have worked on steps 11-17 together during team meetings. I implemented step 15 myself:
https://github.com/doda25-team24/operation/pull/10
