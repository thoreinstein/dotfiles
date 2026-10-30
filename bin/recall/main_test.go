package main

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestObsidianIndex(t *testing.T) {
	state := t.TempDir()
	t.Setenv("XDG_STATE_HOME", state)
	t.Setenv("RECALL_OBSIDIAN_MCP", "")
	if got := obsidianIndex(); got != "" {
		t.Fatalf("no state file: got %q, want empty", got)
	}
	if err := os.MkdirAll(filepath.Join(state, "recall"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(state, "recall", "obsidian-mcp"), []byte("/cache/obsidian-mcp/dist/index.js\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if got := obsidianIndex(); got != "/cache/obsidian-mcp/dist/index.js" {
		t.Fatalf("state file: got %q", got)
	}
	t.Setenv("RECALL_OBSIDIAN_MCP", "/dev/checkout/dist/index.js")
	if got := obsidianIndex(); got != "/dev/checkout/dist/index.js" {
		t.Fatalf("env override: got %q", got)
	}
}

func TestKeywords(t *testing.T) {
	got := keywords("Where did I land on the Terragrunt repo-consolidation work, and the TG work?")
	want := []string{"land", "terragrunt", "repo-consolidation", "work"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %q, want %q", got, want)
	}
	var many []string
	for i := range maxKeywords + 5 {
		many = append(many, fmt.Sprintf("word%02d", i))
	}
	if n := len(keywords(strings.Join(many, " "))); n != maxKeywords {
		t.Fatalf("got %d keywords, want %d", n, maxKeywords)
	}
}

func TestParseEngram(t *testing.T) {
	out := []byte(`
Found 2 memories:

[1] #375 (session_summary) — Compaction recovery summary
    ## Goal
[not a header] #1 (x) — y
    2026-10-09 11:52:12 | project: dotfiles | scope: project

[2] #513 (decision) — ci-fix skill: fix all red checks
    **What**: ...
    2026-10-22 10:32:00 | project: work-thing | scope: project
`)
	got := parseEngram(out)
	want := []hit{
		{key: "engram:375", line: "engram #375 (session_summary) Compaction recovery summary", project: "dotfiles",
			text: "compaction recovery summary\n    ## goal\n[not a header] #1 (x) — y"},
		{key: "engram:513", line: "engram #513 (decision) ci-fix skill: fix all red checks", project: "work-thing",
			text: "ci-fix skill: fix all red checks\n    **what**: ..."},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v\nwant %+v", got, want)
	}
}

func TestParseVault(t *testing.T) {
	out := []byte(`Results:
---
File: a/One.md
Meta: reference · 2026-02-09 · type: clipping
Section: One > Rationale
Content: Some content
---
File: b/Two.md
File: c/Three.md
Section: Three
Section: stray second section
File: engram/dotfiles/decision/gauth-switcher-561.md
Section: gauth
File: engram/_sessions/35bc6e68-02a3-1234.md
`)
	got := parseVault(out)
	want := []hit{
		{key: "vault:a/One.md#One > Rationale", line: "vault a/One.md § One > Rationale", path: "a/One.md"},
		{key: "vault:b/Two.md", line: "vault b/Two.md", path: "b/Two.md"},
		{key: "vault:c/Three.md#Three", line: "vault c/Three.md § Three", path: "c/Three.md"},
		{key: "engram:561", line: "vault engram/dotfiles/decision/gauth-switcher-561.md § gauth",
			path: "engram/dotfiles/decision/gauth-switcher-561.md"},
		{key: "vault:engram/_sessions/35bc6e68-02a3-1234.md", line: "vault engram/_sessions/35bc6e68-02a3-1234.md",
			path: "engram/_sessions/35bc6e68-02a3-1234.md"},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v\nwant %+v", got, want)
	}
}

func TestFirst(t *testing.T) {
	a, b, c, d := hit{key: "a"}, hit{key: "b"}, hit{key: "c"}, hit{key: "d"}
	got := first([]hit{a, b, c, d}, map[string]bool{"b": true})
	if want := []hit{a, c, d}; !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}

func TestUnseen(t *testing.T) {
	t.Setenv("TMPDIR", t.TempDir())
	a, b := hit{key: "a", line: "A"}, hit{key: "b", line: "B"}
	if got := unseen("s/1", []hit{a}); len(got) != 1 {
		t.Fatalf("first call: got %v", got)
	}
	if got := unseen("s/1", []hit{a, b}); !reflect.DeepEqual(got, []hit{b}) {
		t.Fatalf("second call: got %v", got)
	}
	if got := unseen("other", []hit{a}); len(got) != 1 {
		t.Fatalf("other session: got %v", got)
	}
}

func TestRelevant(t *testing.T) {
	kw := []string{"recall", "relevance", "built", "day"}
	both := hit{key: "a", text: "recall: prompt-time pointers\n    built with buildgomodule"}
	prefix := hit{key: "b", text: "recalls and relevance"}
	one := hit{key: "c", text: "aerospace built-in defaults"}
	inner := hit{key: "d", text: "holiday prebuilt"}
	got := relevant([]hit{both, prefix, one, inner}, kw)
	if want := []hit{both, prefix}; !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}
