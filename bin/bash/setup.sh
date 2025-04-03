tasks:
  - name: Setup Environment
    init: |
      bin/bash/setup.sh pre-commit ansible 1password boilerplate hugo complete
    command: |
      if [ -d "website" ]; then
        cd website && hugo server -D -F --baseURL $(gp url 1313) --liveReloadPort=443 --appendPort=false --bind=0.0.0.0
      fi
