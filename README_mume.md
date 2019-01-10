---
markdown:
  image_dir: docs
  ignore_from_front_matter: true
  absolute_image_path: false
---

# Decorator

[![LICENSE][LICENSE-shield]][LICENSE]
[![Build status][travis-shield]][repo]
[![Code coverage][code-coverage-shield]][repo]
[![Pub version][pub-version-shield]][pub-link]
[![Commitizen friendly][commitizen-shield]][commitizen]
[![Commitizen style][commitizen-style-shield]][cz-emoji]
[![Maintained][maintenance-shield]][repo]

## :rocket: About

Python's decorators in dart :fireworks:

**Note**: This is a work-in-progress

## :page_facing_up: TOC

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=true} -->

<!-- code_chunk_output -->

1. [:rocket: About](#rocket-about)
2. [:page_facing_up: TOC](#page_facing_up-toc)
3. [:book: Usage](#book-usage)
    1. [1. Decorator annotation](#1-decorator-annotation)
    2. [2. Decorator generator](#2-decorator-generator)
4. [:traffic_light: Versioning](#traffic_light-versioning)
5. [:memo: Milestones](#memo-milestones)
6. [:medal_sports: Principle](#medal_sports-principle)
7. [:busts_in_silhouette: Contributing](#busts_in_silhouette-contributing)
8. [:octocat: Git](#octocat-git)
9. [:lipstick: Code style](#lipstick-code-style)
10. [:white_check_mark: Testing](#white_check_mark-testing)
11. [:sparkles: Features and :bug:bugs](#sparkles-features-and-bugbugs)
12. [:newspaper: Changelog](#newspaper-changelog)
    1. [1. Decorator annotation](#1-decorator-annotation-1)
        1. [0.0.1](#001)
    2. [2. Decorator generator](#2-decorator-generator-1)
        1. [0.0.1](#001-1)
13. [:scroll: License](#scroll-license)

<!-- /code_chunk_output -->

## :book: Usage

### 1. Decorator annotation

@import "decorator/README_mume.md"

### 2. Decorator generator

@import "decorator_generator/README_mume.md"

## :traffic_light: Versioning

This project follows [Semantic Versioning 2.0.0][semver]

## :memo: Milestones

- [ ] Prepare v1.0.0
  - [ ] allow decorating class methods
  - [ ] allow decorating class fields
  - [x] allow decorating top-level methods
  - [ ] allow decorating top-level fields
  - [ ] allow decorating classes
  - [ ] allow decorating libraries

## :medal_sports: Principle

This project follows [The Twelve-Factor App](https://12factor.net/) principle

## :busts_in_silhouette: Contributing

- :fork_and_knife: Fork this repo

- :arrow_down: Clone your forked version  
  `git clone https://github.com/<you>/decorator.git`

- :heavy_plus_sign: Add this repo as a remote  
  `git remote add upstream https://github.com/devkabiir/decorator.git`

- :arrow_double_down: Make sure you have recent changes  
  `git fetch upstream`

- :sparkles: Make a new branch with your proposed changes/fixes/additions  
  `git checkout upstream/master -b name_of_your_branch`

- :bookmark_tabs: Make sure you follow guidelines for [Git](#git)

- :arrow_double_up: Push your changes  
  `git push origin name_of_your_branch`

- :arrows_clockwise: Make a pull request

## :octocat: Git

- :heavy_check_mark: Sign all commits. Learn about [signing-commits]
- Use [commitizen] with [cz-emoji] adapter
- Check existing commits to get an idea
- Run the pre_commit script from project root `pub run pre_commit`
- If you're adding an `and` in your commit message, it should probably be separate commits
- Link relevant issues/commits with a `#` sign in the commit message
- Limit message length per line to 72 characters (excluding space required for linking issues/commits)
- Add commit description if message isn't enough for explaining changes

## :lipstick: Code style

- Maintain consistencies using included `.editorconfig`
- Everything else as per standard dart [guidelines]

## :white_check_mark: Testing

- Add tests for each new addition/feature
- Do not remove/change tests when refactoring
  - unless fixing already broken test.

## :sparkles: Features and :bug:bugs

Please file feature requests and bugs at the [issue-tracker].

## :newspaper: Changelog

Changes for latest release at [github-releases]

@import "CHANGELOG_mume.md"

## :scroll: License

@import "LICENSE"

<!-- Shield aliases -->
[LICENSE-shield]: https://img.shields.io/github/license/devkabiir/decorator.svg
[travis-shield]: https://img.shields.io/travis/com/devkabiir/decorator/master.svg
[code-coverage-shield]: https://img.shields.io/codecov/c/github/devkabiir/decorator/master.svg
[pub-version-shield]: https://img.shields.io/pub/v/decorator.svg
[commitizen-shield]: https://img.shields.io/badge/commitizen-friendly-brightgreen.svg
[commitizen-style-shield]: https://img.shields.io/badge/commitizen--style-emoji-brightgreen.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2019.svg

<!-- Link aliases -->
[cz-emoji]: https://github.com/ngryman/cz-emoji
[commitizen]: http://commitizen.github.io/cz-cli/
[pub-link]: https://pub.dartlang.org/packages/decorator
[repo]: https://github.com/devkabiir/decorator
[guidelines]: https://www.dartlang.org/guides/language/effective-dart/style
[signing-commits]: https://help.github.com/articles/signing-commits/
[issue-tracker]: https://github.com/devkabiir/decorator/issues
[LICENSE]: https://github.com/devkabiir/decorator/blob/master/LICENSE
[semver]: https://semver.org/
[github-releases]: https://github.com/devkabiir/decorator/releases
