import os
import textwrap
from PIL import Image, ImageDraw, ImageFont

# Dimensions for social media preview card
WIDTH = 1200
HEIGHT = 630

# Colors matching the design in screenshot
BG_COLOR = (248, 249, 252)       # Light grey/blue outer background
CARD_TOP_COLOR = (24, 68, 220)    # Deep vibrant blue
CARD_BOT_COLOR = (44, 54, 169)    # Gradient bottom blue
TEXT_WHITE = (255, 255, 255)
TEXT_SUBTITLE = (210, 225, 255)
HEADER_TEXT_COLOR = (30, 40, 70)
PILL_BG = (255, 255, 255, 40)
BUTTON_BG = (255, 255, 255, 30)

# Fonts
FONT_BOLD_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

def create_gradient_card(w, h, top_color, bot_color):
    card = Image.new("RGBA", (w, h))
    draw = ImageDraw.Draw(card)
    for y in range(h):
        r = int(top_color[0] + (bot_color[0] - top_color[0]) * (y / h))
        g = int(top_color[1] + (bot_color[1] - top_color[1]) * (y / h))
        b = int(top_color[2] + (bot_color[2] - top_color[2]) * (y / h))
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
    return card

def draw_rounded_card(base_img, card_img, box, radius):
    mask = Image.new("L", (box[2] - box[0], box[3] - box[1]), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle([0, 0, mask.width, mask.height], radius=radius, fill=255)
    base_img.paste(card_img, (box[0], box[1]), mask)

def generate_social_image(output_path, section_tag, title, description, badge_text="CURRENT PHASE"):
    # Create base canvas
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Load fonts
    font_header = ImageFont.truetype(FONT_BOLD_PATH, 22)
    font_pill = ImageFont.truetype(FONT_BOLD_PATH, 16)
    font_title = ImageFont.truetype(FONT_BOLD_PATH, 42)
    font_desc = ImageFont.truetype(FONT_REG_PATH, 22)
    font_button = ImageFont.truetype(FONT_BOLD_PATH, 18)

    # 1. Top Header Bar
    header_text = f"INFRA BOOTSTRAP TOOLS  |  {section_tag.upper()}"
    draw.text((60, 40), header_text, fill=HEADER_TEXT_COLOR, font=font_header)

    # 2. Main Blue Card
    card_box = (60, 90, 1140, 570)
    card_w = card_box[2] - card_box[0]
    card_h = card_box[3] - card_box[1]

    grad_card = create_gradient_card(card_w, card_h, CARD_TOP_COLOR, CARD_BOT_COLOR)
    card_draw = ImageDraw.Draw(grad_card)

    # 2a. Badge Pill top left of card
    pill_x, pill_y = 40, 35
    pill_text = f"{badge_text}  •  Docs"
    pill_bbox = font_pill.getbbox(pill_text)
    pill_w = (pill_bbox[2] - pill_bbox[0]) + 30
    pill_h = (pill_bbox[3] - pill_bbox[1]) + 16

    card_draw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=15, fill=(255, 255, 255, 45))
    card_draw.text((pill_x + 15, pill_y + 8), pill_text, fill=TEXT_WHITE, font=font_pill)

    # 2b. Hero Title
    title_lines = textwrap.wrap(title, width=32)
    curr_y = pill_y + pill_h + 25
    for line in title_lines[:2]:
        card_draw.text((40, curr_y), line, fill=TEXT_WHITE, font=font_title)
        curr_y += 50

    # 2c. Description
    curr_y += 10
    desc_lines = textwrap.wrap(description, width=62)
    for line in desc_lines[:3]:
        card_draw.text((40, curr_y), line, fill=TEXT_SUBTITLE, font=font_desc)
        curr_y += 32

    # 2d. Action Buttons at bottom
    btn_y = card_h - 75
    btn1_text = "➔ Deep Dive into Docs"
    btn1_bbox = font_button.getbbox(btn1_text)
    btn1_w = (btn1_bbox[2] - btn1_bbox[0]) + 36
    btn1_h = 44

    card_draw.rounded_rectangle([40, btn_y, 40 + btn1_w, btn_y + btn1_h], radius=12, fill=(255, 255, 255, 50))
    card_draw.text((40 + 18, btn_y + 12), btn1_text, fill=TEXT_WHITE, font=font_button)

    btn2_x = 40 + btn1_w + 20
    btn2_text = "Full Architecture View ↗"
    btn2_bbox = font_button.getbbox(btn2_text)
    btn2_w = (btn2_bbox[2] - btn2_bbox[0]) + 36
    btn2_h = 44

    card_draw.rounded_rectangle([btn2_x, btn_y, btn2_x + btn2_w, btn_y + btn2_h], radius=12, fill=(255, 255, 255, 30))
    card_draw.text((btn2_x + 18, btn_y + 12), btn2_text, fill=TEXT_WHITE, font=font_button)

    # Paste rounded card onto base canvas
    draw_rounded_card(img, grad_card, card_box, radius=24)

    # Save image
    rgb_img = img.convert("RGB")
    rgb_img.save(output_path, "PNG")
    print(f"Generated: {output_path}")

DOCS_PAGES = [
    {
        "filename": "overview.png",
        "tag": "Overview",
        "title": "Documentation Overview",
        "desc": "IaC configurations to bootstrap and manage a small self-hosted project or homelab infrastructure."
    },
    {
        "filename": "gs1-getting-started.png",
        "tag": "Getting Started",
        "title": "🚀 Deploy Your Infrastructure",
        "desc": "Deploy single-node expandable infrastructure on DigitalOcean using Ansible and Terraform."
    },
    {
        "filename": "a1-caddy.png",
        "tag": "Reverse Proxy",
        "title": "Caddy Server & SSL",
        "desc": "Simple open-source web server with automatic HTTPS and plugin ecosystem for Docker Swarm."
    },
    {
        "filename": "a2-portainer.png",
        "tag": "Management UI",
        "title": "Portainer Management",
        "desc": "Lightweight management interface to visually interact with Docker containers, logs, and stacks."
    },
    {
        "filename": "b1-ansible-concepts.png",
        "tag": "Core Concepts",
        "title": "Understanding Ansible Concepts",
        "desc": "Learn how Playbooks, Roles, Tasks, and Inventories drive automation in infra-bootstrap-tools."
    },
    {
        "filename": "b2-terraform-ansible.png",
        "tag": "Provisioning",
        "title": "Spinning Up Infrastructure",
        "desc": "Combine Terraform and Ansible for automated cloud resource provisioning and configuration management."
    },
    {
        "filename": "b3-docker-swarm.png",
        "tag": "Clustering",
        "title": "Docker Swarm Setup",
        "desc": "Automated deployment and management of high-availability Docker Swarm manager and worker nodes."
    },
    {
        "filename": "1password-cli.png",
        "tag": "Secret Management",
        "title": "1Password CLI Integration",
        "desc": "Securely fetch secrets and credentials dynamically during Ansible playbook runs."
    },
    {
        "filename": "boilerplate.png",
        "tag": "Templating",
        "title": "Boilerplate (Gruntwork)",
        "desc": "Generate reusable code structures and standardized Ansible role templates."
    },
    {
        "filename": "hugo.png",
        "tag": "Static Site",
        "title": "Hugo Documentation Engine",
        "desc": "Fast static site generator powering the infra-bootstrap-tools documentation hub."
    },
    {
        "filename": "nix.png",
        "tag": "Environments",
        "title": "Nix Reproducible Workspaces",
        "desc": "Declarative, reproducible development environment using Nix flakes across Linux and macOS."
    },
    {
        "filename": "pre-commit.png",
        "tag": "Code Quality",
        "title": "Pre-commit Defense Framework",
        "desc": "Automate code quality checks, linter runs, and secret scanning before git commits."
    }
]

if __name__ == "__main__":
    out_dir = "website/static/images/og"
    os.makedirs(out_dir, exist_ok=True)
    for page in DOCS_PAGES:
        out_path = os.path.join(out_dir, page["filename"])
        generate_social_image(out_path, page["tag"], page["title"], page["desc"])
