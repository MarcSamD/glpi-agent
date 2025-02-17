  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    ( $name, $start, $end, $credential, $description ) = ( "", "", "", "", "" );
    $cred = $credentials{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name         = $cred->{name} || $this || $form{"input/name"} || "";
    $id           = $cred->{id}   || "";
    $version      = $cred->{snmpversion}  || $form{"input/snmpversion"}  || $form{snmpversion} || $snmpversion || "";
    $community    = $cred->{community}    || $form{"input/community"}    || "";
    $username     = $cred->{username}     || $form{"input/username"}     || "";
    $remoteuser   = $cred->{username}     || $form{"input/remoteuser"}   || "";
    $remotepass   = $cred->{password}     || $form{"input/remotepass"}   || "";
    $type         = $cred->{type}         || $form{"input/type"}         || ($form{remotecreds} ? "ssh" : "snmp");
    $authprotocol = $cred->{authprotocol} || $form{"input/authprotocol"} || "";
    $authpassword = $cred->{authpassword} || $form{"input/authpassword"} || "";
    $privprotocol = $cred->{privprotocol} || $form{"input/privprotocol"} || "";
    $privpassword = $cred->{privpassword} || $form{"input/privpassword"} || "";
    $description  = $cred->{description}  || $form{"input/description"}  || "";
    $port         = $cred->{port}         || $form{"input/port"}         || "";
    $protocol     = $cred->{protocol}     || $form{"input/protocol"}     || "";
    $mode         = $cred->{mode}         || $form{"input/mode"}         || "";
    %modes = map { $_ => 1 } split(',', $mode);
    $credentials{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; credential"), ($cred->{name} || $this))
      : _"Add new credential"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}' autocomplete='off'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <input type='hidden' name='remotecreds' id='remotecreds' value='{$form{remotecreds}||""}'/>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' value='{$name}' size='20'{($id ? " title='Id: $id'" : "")} required />
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='type-option' style='display: flex'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
        <div class='form-edit-row' id='type-options'>
          <input type="radio" name="input/type" id="snmp" value="snmp" onchange="type_change(this)"{$type eq "snmp" ? " checked" : ""}/>
          <label for='snmp'>snmp</label>
          <input type="radio" name="input/type" id="ssh" value="ssh" onchange="type_change(this)"{$type eq "ssh" ? " checked" : ""}/>
          <label for='ssh'>ssh</label>
          <input type="radio" name="input/type" id="winrm" value="winrm" onchange="type_change(this)"{$type eq "winrm" ? " checked" : ""}/>
          <label for='winrm'>winrm</label>
          <input type="radio" name="input/type" id="esx" value="esx" onchange="type_change(this)"{$type eq "esx" ? " checked" : ""}/>
          <label for='esx'>esx</label>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='snmp-version-option' style='display: {$type eq "snmp" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label>{_"Version"}</label>
        <div class='form-edit-row' id='snmp-version-options'>
          <input type="radio" name="input/snmpversion" id="v1" value="v1" onchange="version_change()"{$version && $version eq "v1" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}/>
          <label for='v1'>v1</label>
          <input type="radio" name="input/snmpversion" id="v2c" value="v2c" onchange="version_change()"{!$version || $version eq "v2c" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}/>
          <label for='v2c'>v2c</label>
          <input type="radio" name="input/snmpversion" id="v3" value="v3" onchange="version_change()"{$version && $version eq "v3" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}/>
          <label for='v3'>v3</label>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='v1-v2c-option' style='display: {$type eq "snmp" && (!$version || $version =~ /v1|v2c/) ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='community'>{_"Community"}</label>
        <input class='input-row' type='text' id='community' name='input/community' placeholder='public' value='{$community}'{$type ne "snmp" || $version eq "v3" ? " disabled" : ""} required />
      </div>
    </div>
    <div class='form-edit-row' id='v3-options' style='display: {$type eq "snmp" && $version && $version eq "v3" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='username'>{_"Username"}</label>
        <input class='input-row' type='text' id='username' name='input/username' value='{$username}' size='12' autocomplete='new-password'{$type ne "snmp" || $version ne "v3" ? " disabled" : ""} required />
      </div>
      <div class='form-edit'>
        <label for='authproto'>{_"Authentication protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='authproto' name='input/authprotocol' {$type eq "snmp" && (!$version || $version ne "v3") ? " disabled" : ""}>
            <option{$authprotocol ? "" : " selected"}></option>
            <option{$authprotocol eq "md5" ? " selected" : ""}>md5</option>
            <option{$authprotocol eq "sha" ? " selected" : ""}>sha</option>
          </select>
        </div>
        <label for='authpass'>{_"Authentication password"}</label>
        <div class='form-edit-row'>
          <input class='input-row' id='authpass' type='password' name='input/authpassword' value='{$authpassword}' size='20' autocomplete='new-password'{!$version || $version ne "v3" ? " disabled" : ""}/>
          <i class='pass-eye ti ti-eye' onclick='show_password(this, "authpass")' title='{_"Show password"}'></i>
        </div>
      </div>
      <div class='form-edit'>
        <label for='privproto'>{_"Privacy protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='privproto' name='input/privprotocol' {!$version || $version ne "v3" ? " disabled" : ""}>
            <option{$privprotocol ? "" : " selected"}></option>
            <option{$privprotocol eq "des" ? " selected" : ""}>des</option>
            <option{$privprotocol eq "aes" ? " selected" : ""}>aes</option>
            <option{$privprotocol eq "3des" ? " selected" : ""}>3des</option>
          </select>
        </div>
        <label for='authpass'>{_"Privacy password"}</label>
        <div class='form-edit-row'>
          <input class='input-row' id='privpass' type='password' name='input/privpassword' value='{$privpassword}' size='20' autocomplete='new-password'{!$version || $version ne "v3" ? " disabled" : ""}/>
          <i class='pass-eye ti ti-eye' onclick='show_password(this, "privpass")' title='{_"Show password"}'></i>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='remote-options' style='display: {$type ne "snmp" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='remoteuser'>{_"Username"}</label>
        <input class='input-row' type='text' id='remoteuser' name='input/remoteuser' value='{$remoteuser}' size='12' autocomplete='new-password'{$type eq "snmp" ? " disabled" : ""} required />
      </div>
      <div class='form-edit'>
        <label for='remotepass'>{_"Authentication password"}</label>
        <div class='form-edit-row'>
          <input class='input-row'  type='password' id='remotepass' name='input/remotepass' value='{$remotepass}' size='24' autocomplete='new-password'{$type eq "snmp" ? " disabled" : ""}/>
          <i class='pass-eye ti ti-eye' onclick='show_password(this, "remotepass")' title='{_"Show password"}'></i>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='advanced-options' style='display: {$type ne "esx" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='port'>{_"Port"}</label>
        <input class='input-row input-number' type='number' id='port' name='input/port'  min='1' max='65535' placeholder='{$type eq "ssh" ? 22 : $type eq "winrm" && $modes{ssl} ? 5986 : $type eq "winrm" ? 5985 : 161}' value='{$port}' size='7'{$type eq "esx" ? " disabled" : ""}/>
      </div>
      <div class='form-edit' id='advanced-options-protocol' style='display: {$type eq "snmp" ? "flex" : "none"}'>
        <label for='protocol'>{_"Protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='protocol' name='input/protocol'{$type ne "snmp" ? " disabled" : ""}>
            <option{!protocol || $protocol eq "udp" ? " selected" : ""}>udp</option>
            <option{$protocol eq "tcp" ? " selected" : ""}>tcp</option>
          </select>
        </div>
      </div>
      <div class='form-edit' id='advanced-options-ssh-mode' style='display: {$type eq "ssh" ? "flex" : "none"}'>
        <label>{_"Remote SSH Mode"}</label>
        <div class='form-edit-row'>
          <ul>
            <li><input type='checkbox' id='ssh-mode' name='checkbox/mode/ssh'{$modes{ssh} ? " checked" : ""}{$type ne "ssh" ? " disabled" : ""}/>ssh</li>
            <li><input type='checkbox' id='libssh2-mode' name='checkbox/mode/libssh2'{$modes{libssh2} ? " checked" : ""}{$type ne "ssh" ? " disabled" : ""}/>libssh2</li>
            <li><input type='checkbox' id='perl-mode' name='checkbox/mode/perl'{$modes{perl} ? " checked" : ""}{$type ne "ssh" ? " disabled" : ""}/>perl</li>
          </ul>
        </div>
      </div>
      <div class='form-edit' id='advanced-options-winrm-mode' style='display: {$type eq "winrm" ? "flex" : "none"}'>
        <label>{_"Remote WinRM Mode"}</label>
        <div class='form-edit-row'>
          <ul>
            <li><input type='checkbox' id='ssl' name='checkbox/mode/ssl' onchange="type_change()"{$modes{ssl} ? " checked" : ""}{$type ne "winrm" ? " disabled" : ""}/>ssl</li>
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='description'>{_"Description"}</label>
        <input class='input-row' type='text' id='description' name='input/description' value='{$description}' size='40'/>
      </div>
    </div>
    <button type='submit' class='big-button' name='submit/{
      $credentials{$edit} ?
        "update' alt='"._("Update") :
        "add' alt='"._("Create Credential")}' value='1'><i class='primary ti ti-device-floppy'></i>{ $credentials{$edit} ? _("Update") : _("Create Credential") }</button>
    <button type='submit' class='big-button secondary-button' name='submit/back-to-list' formnovalidate='1' value='1' alt='{_("Go back to list")}'><i class='primary ti ti-x'></i>{_("Go back to list")}</button>
  </form>
  <script>
  function version_change() \{
    if (document.getElementById("v3").checked) \{
      document.getElementById("v1-v2c-option").style = "display: none";
      document.getElementById("v3-options").style = "display: flex";
      change_disabled_in_form(true);
    \} else \{
      document.getElementById("v3-options").style = "display: none";
      document.getElementById("v1-v2c-option").style = "display: flex";
      change_disabled_in_form(false);
    \}
  \}
  function change_disabled_in_form(b) \{
      document.getElementById("community").disabled=b;
      document.getElementById("username").disabled=!b;
      document.getElementById("authproto").disabled=!b;
      document.getElementById("authpass").disabled=!b;
      document.getElementById("privproto").disabled=!b;
      document.getElementById("privpass").disabled=!b;
  \}
  function type_change(type) \{
    if (!type) type = document.getElementById("winrm");
    if (type.value === "snmp") \{
      document.getElementById("remote-options").style = "display: none";
      document.getElementById("snmp-version-option").style = "display: flex";
      document.getElementById("remotecreds").value = "0";
      document.getElementById("port").placeholder = "161";
      document.getElementById("advanced-options-protocol").style = "display: flex";
      document.getElementById("protocol").disabled = false;
      document.getElementById("v1").disabled = false;
      document.getElementById("v2c").disabled = false;
      document.getElementById("v3").disabled = false;
      document.getElementById("community").disabled = false;
      document.getElementById("username").disabled = false;
      document.getElementById("authproto").disabled = false;
      document.getElementById("authpass").disabled = false;
      document.getElementById("privproto").disabled = false;
      document.getElementById("privpass").disabled = false;
      document.getElementById("remoteuser").disabled = true;
      document.getElementById("remotepass").disabled = true;
      version_change();
    \} else \{
      document.getElementById("v3-options").style = "display: none";
      document.getElementById("v1-v2c-option").style = "display: none";
      document.getElementById("snmp-version-option").style = "display: none";
      document.getElementById("remote-options").style = "display: flex";
      document.getElementById("remotecreds").value = "1";
      document.getElementById("advanced-options-protocol").style = "display: none";
      document.getElementById("protocol").disabled = true;
      document.getElementById("v1").disabled = true;
      document.getElementById("v2c").disabled = true;
      document.getElementById("v3").disabled = true;
      document.getElementById("community").disabled = true;
      document.getElementById("username").disabled = true;
      document.getElementById("authproto").disabled = true;
      document.getElementById("authpass").disabled = true;
      document.getElementById("privproto").disabled = true;
      document.getElementById("privpass").disabled = true;
      document.getElementById("remoteuser").disabled = false;
      document.getElementById("remotepass").disabled = false;
    \}
    if (type.value === "ssh") \{
      document.getElementById("advanced-options-ssh-mode").style = "display: flex";
      document.getElementById("port").placeholder = "22";
      document.getElementById("ssh-mode").disabled = false;
      document.getElementById("libssh2-mode").disabled = false;
      document.getElementById("perl-mode").disabled = false;
    \} else \{
      document.getElementById("advanced-options-ssh-mode").style = "display: none";
      document.getElementById("ssh-mode").disabled = true;
      document.getElementById("libssh2-mode").disabled = true;
      document.getElementById("perl-mode").disabled = true;
    \}
    if (type.value === "winrm") \{
      document.getElementById("advanced-options-winrm-mode").style = "display: flex";
      document.getElementById("ssl").disabled = false;
      if (document.getElementById("ssl").checked) \{
        document.getElementById("port").placeholder = "5986";
      \} else \{
        document.getElementById("port").placeholder = "5985";
      \}
    \} else \{
      document.getElementById("advanced-options-winrm-mode").style = "display: none";
      document.getElementById("ssl").disabled = true;
    \}
    if (type.value === "esx") \{
      document.getElementById("advanced-options").style = "display: none";
      document.getElementById("port").disabled = true;
    \} else \{
      document.getElementById("advanced-options").style = "display: flex";
      document.getElementById("port").disabled = false;
    \}
  \}
  function show_password(i,id) \{
    var type = document.getElementById(id).type;
    document.getElementById(id).type = type === "password" ? "text" : "password";
    i.className = type === "password" ? "pass-eye ti ti-eye-off" : "pass-eye ti ti-eye";
    i.title = type === "password" ? "{_('Hide password')}" : "{_('Show password')}";
  \}
  </script>
