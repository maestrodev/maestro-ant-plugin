# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe MaestroDev::AntWorker do

  ANT_VERSION = 'version 1.8.2'
  before(:all) do
    Maestro::MaestroWorker.mock!
  end

  describe 'valid_workitem?' do
    it "should validate fields" do
      workitem = {'fields' =>{}}

      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should include('missing field path')
    end

    it "should detect ant" do
      workitem = {'fields' => {'tasks' => '', 'path' => '/tmp', 'ant_executable' => '/dev/nul'}}

      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should include('ant is not installed')
    end

    it "should error if version detected" do
      workitem = {'fields' => {'tasks' => '',
                               'path' => '/tmp',
                               'ant_version' => '99.99.99'}}
                               
      subject.perform(:execute, workitem)
      
      workitem['fields']['__error__'].should include('ant is the wrong version: ')
    end

    it "should error if propertyfile not found" do
      workitem = {'fields' => {'tasks' => '',
                               'path' => '/tmp',
                               'ant_version' => '1.8.2',
                               'propertyfile' => '/tmp/blah.ant.xml'}}

      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should include('property file not found: /tmp/blah.ant.xml')
    end

    it "should not error if everything is ok" do
      `touch /tmp/test.ant.xml`

      workitem = {'fields' => {'tasks' => '',
                               'path' => '/tmp',
                               'ant_version' => '1.8.2',
                               'propertyfile' => '/tmp/test.ant.xml'}}

      subject.perform(:execute, workitem)

      # This string indicates it got as far as running Ant, which implies the config was ok
      workitem['fields']['__error__'].should include("Buildfile: build.xml does not exist!\nBuild failed\n")
    end
  end

  describe 'execute' do
    before :all do
      @path = File.join(File.dirname(__FILE__), '..', '..')
      @workitem =  {'fields' => {'tasks' => '',
                                 'path' => @path,
                                 'ant_version' => '1.8.2'}}
    end

    it 'should run ant' do
      workitem = {'fields' => {'tasks' => '-version',
                               'path' => @path}}

      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should be_nil
      workitem['__output__'].should include(ANT_VERSION)
      workitem['__output__'].should_not include("ERROR")
    end

    it 'should add propertyfile and environment to command line' do
      pfile = File.join(File.dirname(__FILE__), '..', 'spec-data', 'ant.properties')
      workitem = {'fields' => {'tasks' => '-version',
                               'path' => @path,
                               'environment' => 'HOME=/tmp',
                               'propertyfile' => pfile}}

      subject.perform(:execute, workitem)

      expected = "HOME=/tmp cd #{@path}; ant -q -propertyfile #{pfile} -version"
      workitem['fields']['command'].should eql(expected)
    end

    it 'should not add propertyfile or environment to command line' do
      workitem = {'fields' => {'tasks' => '-version',
                               'path' => @path}}

      subject.perform(:execute, workitem)

      expected = " cd #{@path}; ant -q  -version"
      workitem['fields']['command'].should eql(expected)
    end
  end
end
