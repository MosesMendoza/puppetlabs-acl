require 'puppet/type'
require 'pathname'

Puppet::Type.type(:acl).provide :windows do
  #confine :feature => :microsoft_windows
  confine :operatingsystem => :windows
  defaultfor :operatingsystem => :windows


  require Pathname.new(__FILE__).dirname + '../../../' + 'puppet/type/acl/ace'
  require Pathname.new(__FILE__).dirname + '../../../' + 'puppet/provider/acl/windows/base'
  include Puppet::Provider::Acl::Windows::Base

  has_features :ace_order_required
  has_features :can_inherit_parent_permissions

  def initialize(value={})
    super(value)
    @property_flush = {}
    @security_descriptor = nil
  end

  def self.instances
    []
  end

  def exists?
    case @resource[:target_type]
      when :file
        return ::File.exist?(@resource[:target])
      else
        raise Puppet::ResourceError, "At present only :target_type => :file is supported on Windows."
    end
  end

  def create
    case @resource[:target_type]
      when :file
        raise Puppet::Error.new("ACL cannot create target resources. Target resource will already have a security descriptor on it when created. Ensure target '#{@resource[:target]}' exists.") unless ::File.exist?(@resource[:target])
      else
        raise Puppet::ResourceError, "At present only :target_type => :file is supported on Windows."
    end
  end

  def destroy
    case @resource[:target_type]
      when :file
        raise Puppet::Error.new("ACL cannot remove target resources, only permissions from those target resources. Ensure you pass non-inherited permissions to remove.") unless @resource[:permissions]
      else
        raise Puppet::ResourceError, "At present only :target_type => :file is supported on Windows."
    end
  end

  def permissions
    get_current_permissions
  end

  def permissions=(value)
    non_existing_users = []
    value.each do |permission|
      non_existing_users << permission.identity unless get_account_id(permission.identity)
    end
    raise Puppet::Error.new("Failed to set permissions for '#{non_existing_users.join(', ')}': User or users do not exist.") unless non_existing_users.empty?

    @property_flush[:permissions] = value
  end

  def permissions_insync?(current, should)
    are_permissions_insync?(current, should, @resource[:purge] == :true)
  end

  def permissions_to_s(permissions)
    return '' if permissions.nil? or !permissions.kind_of?(Array)

    perms = permissions.select { |p| !p.is_inherited}

    unless perms.nil?
      perms.each do |perm|
        perm.identity = get_account_name(perm.identity) || perm.identity
      end
    end

    #TODO [BUG][DISPLAY ONLY] This can cause issues when the current displays the unmanaged items (that are not purged) while the should displays something that is being appended to the current set
    perms
  end

  def owner
   get_current_owner
  end

  def owner=(value)
    raise Puppet::Error.new("Failed to set owner to '#{value}': User does not exist.") unless get_account_id(value)

    @property_flush[:owner] = value
  end

  def owner_insync?(current, should)
    is_account_insync?(current,should)
  end

  def owner_to_s(current_value)
    get_account_name(current_value) || current_value
  end

  def group
   get_current_group
  end

  def group=(value)
    raise Puppet::Error.new("Failed to set group to '#{value}': Group does not exist.") unless get_account_id(value)

    @property_flush[:group] = value
  end

  def group_insync?(current, should)
    is_account_insync?(current,should)
  end

  def group_to_s(current_value)
    get_account_name(current_value) || current_value
  end

  def inherit_parent_permissions
    is_inheriting_permissions?
  end

  def inherit_parent_permissions=(value)
    @property_flush[:inherit_parent_permissions] = value
  end

  def flush
    #require 'pry';binding.pry
    sd = get_security_descriptor

    sd.owner = get_account_id(@property_flush[:owner]) if @property_flush[:owner]
    sd.group = get_account_id(@property_flush[:group]) if @property_flush[:group]
    sd.protect = resource.munge_boolean(@property_flush[:inherit_parent_permissions]) == :false if @property_flush.has_key?(:inherit_parent_permissions)

    if @property_flush.has_key?(:inherit_parent_permissions) || @property_flush[:owner] || @property_flush[:group]
      # If owner/group/protect change, we should save the SD and reevaluate for sync of permissions
      set_security_descriptor(sd)
      sd = get_security_descriptor
    end

    # There is a possibility someone will get a message of permissions changing the first time they make
    # changes to owner/group/protect even if the outcome of making those changes would have resulted in
    # the DACL being in sync. Since there is a change on the resource, I think we are fine with the extra
    # message in the report as Puppet figures things out. It will apply the sync based on what the actual
    # permissions are after setting owner, group, and protect.
    if @property_flush[:permissions]
      dacl = convert_to_dacl(sync_aces(sd.dacl,@property_flush[:permissions],@resource[:purge] == :true))
      set_security_descriptor(Puppet::Util::Windows::SecurityDescriptor.new(sd.owner,sd.group,dacl,sd.protect))
    end

    @property_flush.clear
  end
end
