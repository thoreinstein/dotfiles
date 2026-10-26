package main

import (
	"reflect"
	"testing"
)

func TestKeywords(t *testing.T) {
	got := keywords("Where did I land on the Terragrunt repo-consolidation work, and the TG work?")
	want := []string{"land", "terragrunt", "repo-consolidation", "work"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %q, want %q", got, want)
	}
	if n := len(keywords("alpha bravo charlie delta echo foxtrot golf hotel india juliet")); n != maxKeywords {
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
		{key: "engram:375", line: "engram #375 (session_summary) Compaction recovery summary", project: "dotfiles"},
		{key: "engram:513", line: "engram #513 (decision) ci-fix skill: fix all red checks", project: "work-thing"},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v\nwant %+v", got, want)
	}
}

func TestParseVault(t *testing.T) {
	out := []byte(`Results:
File: a/One.md
Section: One > Rationale
Some content
File: b/Two.md
File: c/Three.md
Section: Three
Section: stray second section
`)
	got := parseVault(out)
	want := []hit{
		{key: "vault:a/One.md#One > Rationale", line: "vault a/One.md § One > Rationale", path: "a/One.md"},
		{key: "vault:b/Two.md", line: "vault b/Two.md", path: "b/Two.md"},
		{key: "vault:c/Three.md#Three", line: "vault c/Three.md § Three", path: "c/Three.md"},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v\nwant %+v", got, want)
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
