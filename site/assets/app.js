const REPO = "jajunk/azurelinux-protagonist";
const ISSUE_API = `https://api.github.com/repos/${REPO}/issues?state=open&per_page=30`;

const fallbackIssues = [
  {
    number: 1,
    title: "Inspect Mesa SPEC for hardware driver configuration",
    labels: ["sprint", "mesa", "investigation"],
    html_url: "https://github.com/jajunk/azurelinux-protagonist/issues/1"
  },
  {
    number: 2,
    title: "Define Mesa enablement plan (iris + radeonsi)",
    labels: ["sprint", "mesa"],
    html_url: "https://github.com/jajunk/azurelinux-protagonist/issues/2"
  },
  {
    number: 3,
    title: "Create desktop package gap matrix",
    labels: ["sprint", "investigation"],
    html_url: "https://github.com/jajunk/azurelinux-protagonist/issues/3"
  },
  {
    number: 4,
    title: "Decide desktop environment and write ADR-0003",
    labels: ["sprint", "decision"],
    html_url: "https://github.com/jajunk/azurelinux-protagonist/issues/4"
  },
  {
    number: 5,
    title: "Define minimal ISO / image build path",
    labels: ["sprint", "build"],
    html_url: "https://github.com/jajunk/azurelinux-protagonist/issues/5"
  }
];

document.addEventListener("DOMContentLoaded", () => {
  const page = document.body.dataset.page;
  if (page === "dashboard") {
    loadIssues();
    loadPostList();
  }
  if (page === "post") {
    loadPost();
  }
});

async function loadIssues() {
  const status = document.querySelector("#issue-status");
  const list = document.querySelector("#issue-list");
  if (!list) return;

  try {
    const response = await fetch(ISSUE_API, {
      headers: { Accept: "application/vnd.github+json" }
    });
    if (!response.ok) throw new Error(`GitHub API returned ${response.status}`);

    const data = await response.json();
    const issues = data
      .filter((item) => !item.pull_request)
      .sort((a, b) => scoreIssue(b) - scoreIssue(a))
      .slice(0, 8)
      .map(normalizeIssue);

    renderIssues(issues.length ? issues : fallbackIssues, false);
    status.textContent = issues.length ? `${issues.length} open issues shown` : "No open issues returned";
  } catch (error) {
    renderIssues(fallbackIssues, true);
    status.textContent = "Showing fallback issue links";
  }
}

function scoreIssue(issue) {
  const labels = (issue.labels || []).map((label) => label.name || label);
  return (labels.includes("sprint") ? 10 : 0) + (labels.includes("mesa") ? 4 : 0);
}

function normalizeIssue(issue) {
  return {
    number: issue.number,
    title: issue.title,
    labels: (issue.labels || []).map((label) => label.name || label),
    html_url: issue.html_url
  };
}

function renderIssues(issues, isFallback) {
  const list = document.querySelector("#issue-list");
  list.innerHTML = issues
    .map((issue) => {
      const labels = issue.labels
        .slice(0, 3)
        .map((label) => `<span>${escapeHtml(label)}</span>`)
        .join("");
      const fallbackClass = isFallback ? " fallback" : "";
      return `
        <a class="issue-card${fallbackClass}" href="${issue.html_url}">
          <strong>#${issue.number} ${escapeHtml(issue.title)}</strong>
          <span class="issue-labels">${labels}</span>
        </a>
      `;
    })
    .join("");
}

async function loadPostList() {
  const target = document.querySelector("#post-list");
  if (!target) return;

  try {
    const response = await fetch("posts/index.json");
    if (!response.ok) throw new Error(`Post index returned ${response.status}`);
    const posts = await response.json();
    target.innerHTML = posts
      .map((post) => `
        <article class="post-card">
          <time datetime="${escapeHtml(post.date)}">${formatDate(post.date)}</time>
          <h3><a href="post.html?post=${encodeURIComponent(post.slug)}">${escapeHtml(post.title)}</a></h3>
          <p>${escapeHtml(post.summary)}</p>
        </article>
      `)
      .join("");
  } catch (error) {
    target.innerHTML = `<p class="empty-state">Changelog posts could not be loaded.</p>`;
  }
}

async function loadPost() {
  const target = document.querySelector("#post-content");
  if (!target) return;

  const slug = new URLSearchParams(window.location.search).get("post");
  if (!slug || !/^[a-z0-9-]+$/.test(slug)) {
    renderPostError(target, "Post not found.");
    return;
  }

  try {
    const response = await fetch(`posts/${slug}.md`);
    if (!response.ok) throw new Error(`Post returned ${response.status}`);
    const text = await response.text();
    const { frontMatter, body } = parseFrontMatter(text);
    document.title = `${frontMatter.title || "Changelog"} | ProtagonistOS`;
    target.innerHTML = `
      <header class="post-header">
        <p class="eyebrow">Changelog</p>
        <h1>${escapeHtml(frontMatter.title || "Untitled post")}</h1>
        ${frontMatter.date ? `<time datetime="${escapeHtml(frontMatter.date)}">${formatDate(frontMatter.date)}</time>` : ""}
      </header>
      <div class="markdown-body">${renderMarkdown(body)}</div>
    `;
  } catch (error) {
    renderPostError(target, "This changelog post could not be loaded.");
  }
}

function renderPostError(target, message) {
  target.innerHTML = `
    <header class="post-header">
      <p class="eyebrow">Changelog</p>
      <h1>${escapeHtml(message)}</h1>
    </header>
    <p><a href="index.html#changelog">Return to the changelog.</a></p>
  `;
}

function parseFrontMatter(text) {
  if (!text.startsWith("---")) return { frontMatter: {}, body: text };
  const end = text.indexOf("\n---", 3);
  if (end === -1) return { frontMatter: {}, body: text };

  const raw = text.slice(3, end).trim();
  const frontMatter = {};
  raw.split("\n").forEach((line) => {
    const separator = line.indexOf(":");
    if (separator === -1) return;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^["']|["']$/g, "");
    frontMatter[key] = value;
  });

  return { frontMatter, body: text.slice(end + 4).trim() };
}

function renderMarkdown(markdown) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  const html = [];
  let paragraph = [];
  let list = [];
  let inCode = false;
  let code = [];

  const flushParagraph = () => {
    if (!paragraph.length) return;
    html.push(`<p>${renderInline(paragraph.join(" "))}</p>`);
    paragraph = [];
  };

  const flushList = () => {
    if (!list.length) return;
    html.push(`<ul>${list.map((item) => `<li>${renderInline(item)}</li>`).join("")}</ul>`);
    list = [];
  };

  const flushCode = () => {
    html.push(`<pre><code>${escapeHtml(code.join("\n"))}</code></pre>`);
    code = [];
  };

  for (const line of lines) {
    if (line.startsWith("```")) {
      if (inCode) {
        flushCode();
        inCode = false;
      } else {
        flushParagraph();
        flushList();
        inCode = true;
      }
      continue;
    }

    if (inCode) {
      code.push(line);
      continue;
    }

    if (!line.trim()) {
      flushParagraph();
      flushList();
      continue;
    }

    const heading = line.match(/^(#{1,3})\s+(.+)$/);
    if (heading) {
      flushParagraph();
      flushList();
      const level = heading[1].length + 1;
      html.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
      continue;
    }

    const listItem = line.match(/^- (.+)$/);
    if (listItem) {
      flushParagraph();
      list.push(listItem[1]);
      continue;
    }

    paragraph.push(line.trim());
  }

  flushParagraph();
  flushList();
  if (inCode) flushCode();
  return html.join("");
}

function renderInline(value) {
  return escapeHtml(value)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)]+)\)/g, '<a href="$2">$1</a>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function formatDate(value) {
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("en", {
    year: "numeric",
    month: "long",
    day: "numeric"
  }).format(date);
}
