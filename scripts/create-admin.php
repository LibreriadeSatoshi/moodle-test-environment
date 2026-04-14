<?php
define('CLI_SCRIPT', true);
require(__DIR__ . '/libreria-moodle/config.php');
require_once($CFG->dirroot . '/user/lib.php');

$user = new stdClass();
$user->username = 'admin';
$user->password = 'Admin1234!';
$user->firstname = 'Admin';
$user->lastname = 'Test';
$user->email = 'admin@test.local';
$user->auth = 'manual';
$user->confirmed = 1;
$user->mnethostid = $CFG->mnet_localhost_id;

$userid = user_create_user($user, true, false);

$admins = array_filter(explode(',', (string)($CFG->siteadmins ?? '')));
$admins[] = $userid;
set_config('siteadmins', implode(',', array_unique($admins)));

echo "Created admin user (id={$userid}).\n";
