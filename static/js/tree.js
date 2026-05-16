const branchSelectEl = document.querySelector(".branch-select");
branchSelectEl.addEventListener("change", (event) => {
  let nextUrl = TREE_BRANCH_PATH_TEMPLATE + event.target.value;
  if (typeof TREE_MODE !== "undefined" && TREE_MODE === "top-files") {
    nextUrl += "?mode=top-files";
  }
  window.location.href = nextUrl;
});

branchSelectEl.value = BRANCH_NAME;

// Make the entire row clickable
const fileEls = document.querySelectorAll(".file");

fileEls.forEach(fileEl => {
  fileEl.addEventListener("click", () => {
    window.location = fileEl.querySelector("a").href;
  });
});

const starButtonEl = document.querySelector(".star-button");

async function starRepo(repoId) {
  const url = "/api/v1/repos/" + repoId + "/star";
  const response = await fetch(url, {
    method: "POST"
  });
  const json = await response.json();

  if (json.success) {
    return json.result === "true";
  } else {
    throw new Error(json.message);
  }
}

if (starButtonEl) {
  starButtonEl.addEventListener("click", () => {
    starRepo(REPO_ID)
      .then(() => {
        location.reload()
      })
      .catch((error) => {
        alert(error.toString());
      })
  });
}

const copyCloneURLButton = document.querySelector(".copy-clone-url-button");
if (copyCloneURLButton) {
  copyCloneURLButton.addEventListener("click", async () => {
    const url = document.querySelector(".clone-input-group > input").value;

    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(url);
    }

    alert("The Clipboard API is not available.");
  });
}

const watchButtonEl = document.querySelector(".watch-button");

async function watchRepo(repoId) {
  const url = "/api/v1/repos/" + repoId + "/watch";
  const response = await fetch(url, {
    method: "POST"
  });
  const json = await response.json();

  if (json.success) {
    return json.result;
  } else {
    throw new Error(json.message);
  }
}

if (watchButtonEl) {
  watchButtonEl.addEventListener("click", () => {
    watchRepo(REPO_ID)
      .then(() => {
        location.reload()
      })
      .catch((error) => {
        alert(error.toString());
      })
  });
}

// Poll for file commit info (last_msg, last_hash, last_time) that may still be loading
(function() {
  function findDataEl(attr, value) {
    const els = document.querySelectorAll("[" + attr + "]");
    for (const el of els) {
      if (el.getAttribute(attr) === value) return el;
    }
    return null;
  }

  // Check if any file rows are missing delayed info
  function hasMissingInfo() {
    const msgEls = document.querySelectorAll("[data-msg-for]");
    for (const el of msgEls) {
      const link = el.querySelector("a");
      if (!link || link.textContent.trim() === "") return true;
    }
    if (TREE_FOLDER_SIZE_ENABLED) {
      const sizeEls = document.querySelectorAll("[data-size-for]");
      for (const el of sizeEls) {
        if (el.textContent.trim() === "") return true;
      }
    }
    return false;
  }

  if (!hasMissingInfo()) return;

  const path = typeof CURRENT_PATH !== "undefined" ? CURRENT_PATH : "";
  const apiUrl = "/api/v1/repos/" + REPO_ID + "/tree/files?branch=" +
    encodeURIComponent(BRANCH_NAME) + "&path=" + encodeURIComponent(path);

  let attempts = 0;
  const maxAttempts = 60;

  function applyFiles(files) {
    for (const file of files) {
      if (file.last_msg) {
        const msgEl = findDataEl("data-msg-for", file.name);
        if (msgEl) {
          const link = msgEl.querySelector("a");
          if (link && link.textContent.trim() === "") {
            link.textContent = file.last_msg;
            if (file.last_hash) {
              link.href = "/" + REPO_USER + "/" + REPO_NAME + "/commit/" + file.last_hash;
            }
          }
        }
      }
      const timeEl = findDataEl("data-time-for", file.name);
      if (timeEl && timeEl.textContent.trim() === "" && file.last_time) {
        timeEl.textContent = file.last_time;
      }
      if (TREE_FOLDER_SIZE_ENABLED && file.size) {
        const sizeEl = findDataEl("data-size-for", file.name);
        if (sizeEl && sizeEl.textContent.trim() === "") {
          sizeEl.textContent = file.size;
        }
      }
    }
  }

  function poll() {
    attempts++;
    fetch(apiUrl)
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data && data.success && Array.isArray(data.result)) {
          applyFiles(data.result);
        }
      })
      .catch(function() {})
      .finally(function() {
        if (hasMissingInfo() && attempts < maxAttempts) {
          setTimeout(poll, 2000);
        }
      });
  }

  // Start polling after a short delay to give the background task time to begin
  setTimeout(poll, 1000);
})();
