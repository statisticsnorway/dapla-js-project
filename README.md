> This documentation is immature and work in progress!

# Dapla JS Project

This project aggregates Dapla (Statistics Norway Data Platform) JavaScript sources into a common development context.

## Requirements

* Some scripts might require [jq](https://stedolan.github.io/jq/)
* [Github-cli](https://cli.github.com/) needs to be installed and configured with access to the repositories

## Things of note

* **dapla-js-utilities** has to be built and released first, since almost every other project uses it
* **dapla-workbench** has to be built and released last, since it relies on many other projects as integrations

## TODO

* Handle running specific git-repo-update before dependency updating
* Check if remote repository already has a dependencies-auto-update-[date] branch
* Potentially open PR links in a browser automatically
* Improve `cd` failure handling
* Create a dependency tree of our internal js-projects
* Dependency-check.sh:
    * Improve splitting dependency versions into arrays
    * Improve if-statements
    * Differentiate major/minor/path better (different colors?)
    * Potentially improve output when skipping devDependencies
        * Currently, might show both "0Major, 0Minor, 0Patch" (hidden devDep is outdated) or "Dependencies are up to
          date" (All deps are up-to-date)

## TODO - All projects

* Add Dapla logo
* Rename `master`-branch to `main`
* Utilize release and tagging on GitHub (implement a third pipeline template for production tagging and only deploy to
  production when there is a new release on GitHub)

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

All projects uses Azure Pipline templates from our
[shared template repository](https://github.com/statisticsnorway/azure-pipelines-templates/tree/master/javascript).
