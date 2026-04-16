#!/bin/bash

set -e

export PGPASSWORD='pass'
MOODLEDATA="${MOODLEDATA:-/root/moodledata}"
PSQL=(psql -h localhost -U moodle_user -d moodle -v ON_ERROR_STOP=1)

echo "Truncating log tables..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_logstore_standard_log,
  mdl_log,
  mdl_log_queries,
  mdl_config_log,
  mdl_task_log,
  mdl_events_queue,
  mdl_events_queue_handlers
RESTART IDENTITY;
SQL

echo "Truncating sessions..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE mdl_sessions RESTART IDENTITY;
SQL

echo "Truncating messages and notifications..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_messages,
  mdl_notifications,
  mdl_message_conversations,
  mdl_message_conversation_actions,
  mdl_message_conversation_members,
  mdl_message_user_actions,
  mdl_message_read,
  mdl_message_contacts,
  mdl_message_contact_requests,
  mdl_message_users_blocked,
  mdl_message_email_messages,
  mdl_message_popup,
  mdl_message_popup_notifications,
  mdl_sms_messages
RESTART IDENTITY CASCADE;
SQL

echo "Truncating live auth tokens and devices..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_external_tokens,
  mdl_user_devices,
  mdl_oauth2_access_token,
  mdl_oauth2_refresh_token
RESTART IDENTITY CASCADE;
SQL

echo "Wiping user-authored course content (keeping course structure and activities)..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_forum_posts,
  mdl_forum_discussions,
  mdl_forum_digests,
  mdl_forum_discussion_subs,
  mdl_forum_grades,
  mdl_forum_queue,
  mdl_forum_read,
  mdl_forum_subscriptions,
  mdl_forum_track_prefs,
  mdl_assign_submission,
  mdl_assign_grades,
  mdl_assign_user_flags,
  mdl_assign_user_mapping,
  mdl_assign_overrides,
  mdl_assignfeedback_comments,
  mdl_assignfeedback_editpdf_annot,
  mdl_assignfeedback_editpdf_cmnt,
  mdl_assignfeedback_editpdf_quick,
  mdl_assignfeedback_editpdf_rot,
  mdl_assignfeedback_file,
  mdl_assignsubmission_file,
  mdl_assignsubmission_onlinetext,
  mdl_quiz_attempts,
  mdl_quiz_grades,
  mdl_quiz_overrides,
  mdl_quiz_overview_regrades,
  mdl_quiz_statistics,
  mdl_question_attempts,
  mdl_question_attempt_steps,
  mdl_question_attempt_step_data,
  mdl_lesson_attempts,
  mdl_lesson_branch,
  mdl_lesson_grades,
  mdl_lesson_overrides,
  mdl_lesson_timer,
  mdl_choice_answers,
  mdl_feedback_value,
  mdl_feedback_valuetmp,
  mdl_feedback_completed,
  mdl_feedback_completedtmp,
  mdl_workshop_submissions,
  mdl_workshop_assessments,
  mdl_workshop_grades,
  mdl_workshop_aggregations,
  mdl_data_records,
  mdl_data_content,
  mdl_glossary_entries,
  mdl_glossary_entries_categories,
  mdl_glossary_alias,
  mdl_wiki_pages,
  mdl_wiki_versions,
  mdl_wiki_locks,
  mdl_wiki_subwikis,
  mdl_wiki_synonyms,
  mdl_wiki_links,
  mdl_scorm_attempt,
  mdl_scorm_scoes_data,
  mdl_scorm_scoes_value,
  mdl_scorm_element,
  mdl_scorm_aicc_session,
  mdl_comments,
  mdl_grade_grades,
  mdl_grade_grades_history,
  mdl_course_completions,
  mdl_course_modules_completion,
  mdl_course_completion_crit_compl,
  mdl_attendance_log,
  mdl_attendance_tempusers,
  mdl_attendance_warning_done,
  mdl_tool_monitor_history,
  mdl_tool_monitor_subscriptions
RESTART IDENTITY CASCADE;
SQL

echo "Deleting users (keeping only 'guest') and their associations..."
"${PSQL[@]}" <<'SQL'
DELETE FROM mdl_user_enrolments;
DELETE FROM mdl_user_lastaccess;
DELETE FROM mdl_user_password_history;
DELETE FROM mdl_role_assignments;
DELETE FROM mdl_cohort_members;
DELETE FROM mdl_groups_members;
DELETE FROM mdl_badge_issued;
DELETE FROM mdl_favourite;
DELETE FROM mdl_user WHERE username <> 'guest';
SQL

echo "Truncating residual per-user data (users were already deleted)..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_user_preferences,
  mdl_user_info_data
RESTART IDENTITY;
SQL

echo "Clearing uploaded-file metadata..."
"${PSQL[@]}" <<'SQL'
TRUNCATE TABLE
  mdl_files,
  mdl_files_reference,
  mdl_infected_files,
  mdl_hvp_tmpfiles
RESTART IDENTITY CASCADE;
SQL

echo "Scrub completed."
