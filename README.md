> This documentation is immature and work in progress!

# Dapla JS Project

This project aggregates Dapla (Statistics Norway Data Platform) JavaScript sources into a common development context.

## Requirements

* Some scripts might require [jq](https://stedolan.github.io/jq/)
* [Github-cli](https://cli.github.com/) needs to be installed and configured with access to the repos

## Things of note

* **dapla-js-utilities** and **dapla-workbench** have to be run separately

## TODO

* Check if remote repo has dependencies-auto-update-[date] branch
* Improve `cd` failure handling
* Add default no answer to dependency major version upgrade question
* Find solution for running the script on one repo and not all
* Separate app vs lib handling (currently hardcoded)
* Create a dependency tree of our internal js-projects

## References

* [dapla-js-utilities](https://github.com/statisticsnorway/dapla-js-utilities)
* [dapla-workbench](https://github.com/statisticsnorway/dapla-workbench)
* [dapla-catalog-viewer](https://github.com/statisticsnorway/dapla-catalog-viewer)
* [dapla-lineage-viewer](https://github.com/statisticsnorway/dapla-lineage-viewer)
* [dapla-variable-search](https://github.com/statisticsnorway/dapla-variable-search)
* [dapla-metadata-explorer](https://github.com/statisticsnorway/dapla-metadata-explorer)
* [dapla-metadata-webview](https://github.com/statisticsnorway/dapla-metadata-webview)
* [dapla-user-access-admin](https://github.com/statisticsnorway/dapla-user-access-admin)
* [dapla-react-reference-app](https://github.com/statisticsnorway/dapla-react-reference-app)
* [cra-template-dapla-js-lib](https://github.com/statisticsnorway/cra-template-dapla-js-lib)
* [cra-template-dapla-react-app](https://github.com/statisticsnorway/cra-template-dapla-react-app)
