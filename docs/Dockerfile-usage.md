# Using the dockerfile locally:
You can build the dockerfile locally with:
``` shell
  docker build -t pwsh-local .
```

To run the dockerfile locally with the src folder mounted you can run:
``` shell
  docker run -it --rm -v ${PWD}/src:/src pwsh-local
```
##### Note: on windows, the path has to be fully specified, otherwise you will only see an empty directory mounted in `src`

Now you can run the commands available in the `src` folder and test things out.

1. Run the load-used-actions.ps1 script:
``` powershell
cd ./src

$env:GITHUB_TOKEN = <your github token>

$orgName = 'rajbos'
$marketplaceRepo = ''
$username = 'rajbos'
$userEmail = ''
.\load-used-actions.ps1 -orgName $orgName -PAT $env:GITHUB_TOKEN -marketplaceRepo $marketplaceRepo -userName $username -userEmail $userEmail
```