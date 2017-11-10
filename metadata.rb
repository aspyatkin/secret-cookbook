name 'secret'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
description 'Managing secrets in Chef recipes'
version '1.0.0'

depends 'instance', '~> 2.0.0'

scm_url = 'https://github.com/aspyatkin/secret-cookbook'
source_url scm_url if respond_to?(:source_url)
issues_url "#{scm_url}/issues" if respond_to?(:issues_url)
