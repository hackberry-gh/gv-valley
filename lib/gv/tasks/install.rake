require 'gv/valley'

USER = ENV['VALLEY_USER'] || "val"
HOME = ENV['VALLEY_HOME'] || "/home/#{USER}"
CONFIG_DIR = "/etc/greenvalley/config"

namespace :install do
  
  def capture cmd
    `#{cmd}`.chomp rescue nil
  end
  
  task :config_dir do
    mkdir_p CONFIG_DIR    
  end
  
  task :domain => ['install:config_dir'] do
    unless File.exists? "#{CONFIG_DIR}/domain"
      print "Enter Domain: "
      domain = STDIN.gets.strip
      if domain.empty?
        abort "Domain cannot be blank"
      end
      sh "echo \"#{domain}\" > #{CONFIG_DIR}/domain"    
    end
  end

  task :user => ['install:config_dir'] do
    sh "useradd #{USER}" rescue nil
    sh "chown -R #{USER} #{CONFIG_DIR}"
    sh "echo \"#{USER}\" > #{CONFIG_DIR}/user" unless File.exists? "#{CONFIG_DIR}/user"
    sh "echo \"#{HOME}\" > #{CONFIG_DIR}/home" unless File.exists? "#{CONFIG_DIR}/home"
  end
  
  desc "Install Gitreceive"
  task :gitreceive => ['install:user'] do
    
    sh "wget -O /usr/local/bin/gitreceive https://raw.githubusercontent.com/progrium/gitreceive/master/gitreceive"
    sh "chmod +x /usr/local/bin/gitreceive"
    sh "GITUSER=#{USER} gitreceive init"
    
    cp "#{GV::Valley.root}/scripts/receiver", "#{HOME}/receiver"
    sh "chmod +x #{HOME}/receiver"
    
  end
  
  task :aufs do
    sh "lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`"
  end

  desc "Install Docker"
  task :docker => ['install:aufs','install:user'] do
    if capture('docker -v').nil?  
      sh "egrep -i \"^docker\" /etc/group || groupadd docker"
      sh "usermod -aG docker #{USER}"
      sh "curl https://get.docker.io/gpg | apt-key add -"
      sh "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
      sh "apt-get update"
      sh "apt-get install -y lxc-docker"
      sh "sleep 2" # give docker a moment i guess
    end
  end  
  
  desc "Pull Docker repo"
  task :pull, [:repo] => ['install:docker'] do |t,args|
    if capture("docker images | grep #{args.repo}").empty?
      sh "docker pull #{args.repo}" 
    end
  end 
  
  desc "Pulls flynn/etcd"
  task :etcd do
    Rake::Task['install:pull'].invoke("flynn/etcd")        
  end
  
  desc "Pulls flynn/slugbuilder"
  task :slugbuilder => ['install:docker'] do
    Rake::Task['install:pull'].invoke("flynn/slugbuilder")    
  end
  
  desc "Pulls flynn/slugrunner"
  task :slugrunner => ['install:docker'] do
    Rake::Task['install:pull'].invoke("flynn/slugrunner")    
  end  
  
  desc "Install Haproxy"
  task :haproxy => ['install:user'] do
    if capture("haproxy -v").nil?
      sh "add-apt-repository -y ppa:vbernat/haproxy-1.5"
      sh "apt-get update -y -q"
      sh "apt-get install haproxy -y -q"
      sh "echo \"ENABLED=1\" >> /etc/default/haproxy"
    end
    cp "#{GV::Valley.root}/scripts/haproxy.cfg", "/etc/haproxy/haproxy.cfg"
    sh "usermod -aG haproxy #{USER}"    
    chmod 0770, "/etc/haproxy/haproxy.cfg"
    sh "chgrp haproxy /etc/haproxy/haproxy.cfg"    
  end  
  
  
  desc "Installs bare host to run apps"
  task :host do
    Rake::Task['install:slugrunner'].invoke
  end
  
  desc "Installs Green Valley"
  task :valley => ['install:domain','install:user'] do
    Rake::Task['install:gitreceive'].invoke
    Rake::Task['install:slugbuilder'].invoke
    Rake::Task['install:slugrunner'].invoke   
    Rake::Task['install:haproxy'].invoke      
  end
 
end

task :install => ['install:valley']