base:
  '*':
    - common
    - users
  '*-controller-*':
    - controller
  '*-worker-*':
    - worker

local:
  'local-*':
    - common
