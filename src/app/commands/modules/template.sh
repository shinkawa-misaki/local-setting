#!/usr/bin/env bash
set -e

source "$LOCAL_SETTING/src/app/lib/oo-bootstrap.sh"
basename commands_modules

import util/type
import util/exception
import util-ext/log
import helpers/tool/template
import helpers/dockerProject


DockerProject setting && $var:setting __constructor__ "$(basename ${BASH_SOURCE[0]#/*} .sh)"
string -g project_domain="$($var:setting GetProjectDomain)"
string -g project_dir="$($var:setting GetProjectDir)"
string -g docker_dir="$($var:setting GetDockerDir)"
string -g docker_domain="$($var:setting GetDockerDomain)"

function printAscii() {
  lolcat --speed=5 --spread=1.5 --seed=140 \
    "$(resourceModules)/$(basename "${BASH_SOURCE[0]#/*}" .sh)/ascii.text"
}

function setUP() {
  toolTemplateInstall
}

function setDown() {
  printAscii
}


function init() {
  echo "init start"
  setUP
  $var:setting DeleteProject
  $var:setting GitClone
  $var:setting GitSkip
  $var:setting GitLocalRepositoryHooks
  $var:setting Archive
  $var:setting EnvSetting
  $var:setting AliasSet
  $var:setting DeployLocalSrcFile
  $var:setting ContainerBuild
  $var:setting ContainerInitialize
  $var:setting ProjectCurlCheck
  setDown
}


function update() {
  setUP
  $var:setting DeployLocalSrcFile
  $var:setting ContainerReBuild
  $var:setting ContainerInitialize
  $var:setting ProjectCurlCheck
  setDown
}

# 最新バージョン反映
function latest() {
  echo "latest start"
  setUP
  $var:setting Latest
  $var:setting EnvSetting
  $var:setting ContainerInitialize
  $var:setting ProjectCurlCheck
  setDown
}

# init モード
if [[ "${1}" == "init" ]]; then
  init
fi

# update モードでオプションごとに分岐する。
if [[ "${1}" == "update" ]]; then
  case ${2} in
        "db") updateDataBase "$3" "$4";;
       "env") $var:setting UpdateEnvSetting "$3" "$4" && $var:setting ProjectCurlCheck;;
      "tool") toolTemplateInstall;;
     "alias") $var:setting AliasSet;;
     "hooks") $var:setting GitLocalRepositoryHooks;;
    "latest") latest;;
           *) update;;
  esac
fi

# delete モード：プロジェクト削除とテンプレート削除
if [[ "${1}" == "delete" ]]; then
 $var:setting DeleteProject
 toolTemplateUnInstall
fi
