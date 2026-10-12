import frappe
from frappe.desk.form.assign_to import add as add_assign

AUTHOR_EMAIl = "john@example.com"
AUTHOR_NAME = "John Doe"
CONTENT = """
<div style="font-family: 'Segoe UI', sans-serif; font-size: 15px; line-height: 1.8; color: #374151; max-width: 560px; margin: 0 auto;">
Hey {{ first_name }} 👋,
<br><br>
This is a sample ticket we created to show you how AVA Help Desk works.
<br><br>
In the main <b>Ticket activity area</b>, when you reply to a ticket your response shows up directly below in the activity thread, so you can keep track of all ticket activity in one place. When it's time to follow up, click <b>Reply</b> to send a message to the user. To discuss a ticket internally, use the <b>Comment</b> feature to leave notes visible only to your colleagues.
<br><br>
In the <b>Ticket Sidebar</b> you can assign the ticket, set its priority, type and status. The <b>Ticket Header</b> shows first-response and resolution timers and the ticket source.
<br><br>
What you can do next:<br>
<ul style="padding-left: 20px; margin: 0;">
  <li>Invite your team and auto-assign tickets using assignment rules.</li>
  <li>Set up SLAs to manage response times for your agents.</li>
  <li>Add a Knowledge Base for self-serve support.</li>
</ul>
<br>
Cheers,<br>
AVA Help Desk Team
</div>
"""


def create_welcome_ticket():
    create_contact()
    create_ticket()


def create_ticket():
    if frappe.db.count("HD Ticket"):
        return

    # Render template with the current user's information
    user_doc = frappe.get_doc("User", frappe.session.user)
    if (user_doc.name or "").strip().lower() == "administrator":
        first_name = "there"
    else:
        first_name = (user_doc.first_name or "").strip() or "there"
    rendered_content = frappe.render_template(
        CONTENT,
        {
            "first_name": first_name,
        },
        safe_render=True,
    )

    d = frappe.new_doc("HD Ticket")
    d.subject = "Welcome to AVA Help Desk"
    d.description = rendered_content
    d.raised_by = AUTHOR_EMAIl
    d.contact = AUTHOR_NAME
    d.via_customer_portal = True
    d.insert()
    add_assign(
        {
            "doctype": "HD Ticket",
            "name": d.name,
            "assign_to": ["Administrator"],
        }
    )


def create_contact():
    frappe.get_doc(
        {
            "doctype": "Contact",
            "first_name": AUTHOR_NAME,
            "email_ids": [{"email_id": AUTHOR_EMAIl, "is_primary": 1}],
        }
    ).insert()
