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

I have worked on F6 and F7. 
I forgot to do a pull request for F6 but here's are the commits. 
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


### WEEK 2 (Nov 17-21)

- Bernardini, Giorgio:

- Ibanez, Elena:

I have worked on steps 1 to 11 with Sara together from Sara's laptop.  

- Mititelu, Alexandru:

- Mundala, Wojciech:
I have worked on steps 11-17 together during team meetings. I implemented step 15 myself:
https://github.com/doda25-team24/operation/pull/10

- de Oliveira Cortez, Sara:

I have worked on A1 F9 and F10, workflows and making the code model independent through envIronment variables.

https://github.com/doda25-team24/model-service/pull/2

https://github.com/doda25-team24/model-service/pull/3



### WEEK 3 (Nov 24-28)

- Bernardini, Giorgio:
Fixed steps 15, 16 and 17 together with Sara.
https://github.com/doda25-team24/operation/pull/12

- Ibanez, Elena:

- Mititelu, Alexandru:

- Mundala, Wojciech: Implemented steps 18 and 19. https://github.com/doda25-team24/operation/pull/13

- de Oliveira Cortez, Sara:
  
I have worked on steps 1 to 14:
https://github.com/doda25-team24/operation/commit/24bb522aabc5291964e6fb80f2166eabe0b4a706 (collaborative, accidentally unfortunately directly commited to main)
https://github.com/doda25-team24/operation/pull/6
https://github.com/doda25-team24/operation/pull/8
https://github.com/doda25-team24/operation/pull/9

### WEEK 4 (Dec 1-5)

- Bernardini, Giorgio:
Fixed steps 15, 16 and 17 together with Sara.
https://github.com/doda25-team24/operation/pull/12

- Ibanez, Elena:

- Mititelu, Alexandru:

- Mundala, Wojciech: 

- de Oliveira Cortez, Sara:
Fixed steps 15, 16 and 17 together with Giorgio.
https://github.com/doda25-team24/operation/pull/12


### WEEK 5 (Dec 8-12)

- Ibanez, Elena:
https://github.com/doda25-team24/operation/pull/19

- Mititelu, Alexandru:

- Mundala, Wojciech:
https://github.com/doda25-team24/operation/pull/15
https://github.com/doda25-team24/operation/pull/16
https://github.com/doda25-team24/operation/pull/17

- de Oliveira Cortez, Sara:
https://github.com/doda25-team24/operation/pull/14

### WEEK 6 (Dec 15-19)

- de Oliveira Cortez, Sara:
Updated helm chart with service monitors, updated setup.sh to install prometheus. Troubleshooting minikube/macOS issues.
https://github.com/doda25-team24/operation/pull/20

- Ibanez, Elena: 
https://github.com/doda25-team24/operation/pull/21

- Mundala, Wojciech:
https://github.com/doda25-team24/operation/pull/22
https://github.com/doda25-team24/operation/pull/25


### WEEK 7 (Jan 5-9)

- de Oliveira Cortez, Sara:
Fixed monitoring ingress, implemented custom metrics. Used AI for formatting metrics in SpringBoot specification, in the app repository.
https://github.com/doda25-team24/operation/pull/23
https://github.com/doda25-team24/operation/pull/24
https://github.com/doda25-team24/app/pull/6


- Ibanez, Elena: 
https://github.com/doda25-team24/operation/pull/26

- Mundala, Wojciech:
https://github.com/doda25-team24/operation/pull/27

### WEEK 8 (Jan 12-16)

- de Oliveira Cortez, Sara:
Started traffic management with istio
https://github.com/doda25-team24/operation/pull/28

- Mundala, Wojciech:
https://github.com/doda25-team24/operation/pull/29

### WEEK 9 (Jan 19-23)

- de Oliveira Cortez, Sara:
fixed a2
https://github.com/doda25-team24/operation/pull/32

- Mundala, Wojciech
https://github.com/doda25-team24/operation/pull/30
https://github.com/doda25-team24/operation/pull/31
https://github.com/doda25-team24/operation/pull/33
https://github.com/doda25-team24/operation/pull/34
https://github.com/doda25-team24/operation/pull/35
https://github.com/doda25-team24/operation/pull/36
https://github.com/doda25-team24/operation/pull/37
