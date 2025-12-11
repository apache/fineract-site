# Copyright ©2025 The Apache Software Foundation.
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
# 
# https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

security.html: security.md
	docker run --rm --volume "$(shell pwd):/data" --user $(shell id -u):$(shell id -g) pandoc/minimal:3.8.3 --to html5 --standalone --wrap=none --css css/security.css --variable pagetitle='Apache Fineract Security Reports' --table-of-contents --toc-depth=2 --include-in-header favicon.html --output $@ $<
	cp security.html ../../
