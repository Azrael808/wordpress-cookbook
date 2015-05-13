
def whyrun_supported?
  true
end

action :install do

  if @current_resource.exists
    Chef::Log.info "Plugin #{@new_resource} already exists - nothing to do."
  else
    converge_by("Add plugin #{@new_resource}") do
      add_plugin
    end
  end
end

def add_plugin
  download_and_extract(@new_resource.url, @new_resource.plugin_name)

  # TODO: update/freshen the files in the plugins directory
  bash "overwrite-plugin" do
    cwd "#{node['wordpress']['dir']}/wp-content/plugins"
    code "unzip xf #{Chef::Config[:file_cache_path]}/#{title}.zip"
  end
end

def download_and_extract(url, title)
  Chef::Log.info "Downloading #{title} from #{url}..."

  # Retrieve the file
  remote_file "#{Chef::Config[:file_cache_path]}/#{title}.zip" do
    source url
  end

  # Extract the archive - assuming zip file for now (most WP plugins ship this way)
  bash "extract-plugin" do
    cwd "#{Chef::Config[:file_cache_path]}/#{title}"
    code "unzip xf ../#{title}.zip"
  end
end

def load_current_resource
  @current_resource = Chef::Resource::WordpressPlugin.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.plugin_name(@new_resource.plugin_name)
  @current_resource.url(@new_resource.url)

  if plugin_exists?(@current_resource.url, @current_resource.plugin_name)
    @current_resource.exists = true
  end

  @current_resource
end

def plugin_exists?(url, title)

  Chef::Log.info "Checking existance of #{title} from #{url}..."

  download_and_extract(url, title)

  plugin_dir = `unzip -l #{Chef::Config[:file_cache_path]}/#{title}.zip |grep " [^/]*/$" |awk '{print $4}'`

  if Dir.exist?(plugin_dir)
    return true
  end

  return false
end

