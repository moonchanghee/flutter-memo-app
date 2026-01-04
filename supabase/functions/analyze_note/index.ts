/// <reference lib="deno.ns" />
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ✅ CORS (Flutter Web 대비)
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AnalyzeResult = {
  categoryName: string;
  title: string;
  summary: string[];
  todos: { text: string; due: string | null; priority: "low" | "mid" | "high" }[];
  tags: string[];
};

function slugify(name: string) {
  return name
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9\-가-힣]/g, "");
}

// ✅ 아주 단순 키워드 분류 (무료 MVP)
function classify(content: string): AnalyzeResult {
  const raw = content.trim();
  const text = raw.toLowerCase();

  const rules: { name: string; keywords: string[] }[] = [
    { name: "업무", keywords: ["회의", "보고", "견적", "고객", "메일", "요청", "프로젝트", "업무", "자료", "문서"] },
    { name: "일정", keywords: ["내일", "오늘", "모레", "예약", "일정", "미팅", "약속", "방문", "시간", "날짜"] },
    { name: "공부", keywords: ["공부", "강의", "정리", "복습", "시험", "코딩", "알고리즘", "개발", "flutter", "react"] },
    { name: "아이디어", keywords: ["아이디어", "기획", "서비스", "개선", "기능", "컨셉", "생각", "메모"] },
    { name: "돈/재테크", keywords: ["주식", "코인", "환율", "적금", "대출", "카드", "세금", "보험", "연금", "투자"] },
    { name: "운동/건강", keywords: ["운동", "헬스", "러닝", "식단", "건강", "병원", "약", "검진", "통증"] },
    { name: "개인", keywords: ["가족", "집", "육아", "아이", "친구", "여행", "장보기", "택배", "청소", "요리"] },
  ];

  let best = "기타";
  let bestScore = 0;

  for (const r of rules) {
    let score = 0;
    for (const k of r.keywords) {
      if (text.includes(k)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = r.name;
    }
  }

  // 제목: 첫 줄 20자
  const title = raw.split("\n")[0]ㅔ.slice(0, 20) || "메모";

  // 요약: 너무 길면 앞부분만 1~3개로
  const summary = [];
  if (raw.length <= 120) {
    summary.push(raw);
  } else {
    summary.push(raw.slice(0, 120) + "…");
  }

  // TODO 추출: 줄 단위로 “해야/할것/todo” 포함하면 todo로
  const todos: AnalyzeResult["todos"] = [];
  const lines = raw.split("\n").map((l) => l.trim()).filter(Boolean);
  for (const line of lines) {
    if (/(todo|해야|할 것|해야함|할일)/i.test(line)) {
      todos.push({
        text: line.replace(/^[-*]\s*/, ""),
        due: null,
        priority: "mid",
      });
    }
  }

  const tags = best === "기타" ? [] : [best];

  return { categoryName: best, title, summary, todos, tags };
}

serve(async (req) => {
  // ✅ 브라우저 preflight 처리
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";

    // Supabase Edge 런타임 환경변수
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnon = Deno.env.get("SUPABASE_ANON_KEY")!;

    // ✅ RLS를 통과하려면 "요청자의 JWT"로 DB에 접근해야 함
    const supabase = createClient(supabaseUrl, supabaseAnon, {
      global: { headers: { Authorization: authHeader } },
    });

    const body = await req.json().catch(() => ({}));
    const noteId = body?.note_id as string | undefined;

    if (!noteId) {
      return new Response(JSON.stringify({ ok: false, error: "note_id required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1) note 가져오기
    const { data: note, error: noteErr } = await supabase
      .from("notes")
      .select("id, user_id, content")
      .eq("id", noteId)
      .single();

    if (noteErr || !note) {
      return new Response(JSON.stringify({ ok: false, error: `note fetch failed: ${noteErr?.message ?? "not found"}` }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) 분류 실행
    const result = classify(note.content);

    // 3) categories upsert (user_id + slug 유니크 기준)
    const slug = slugify(result.categoryName);
    const { data: cat, error: catErr } = await supabase
      .from("categories")
      .upsert(
        { user_id: note.user_id, name: result.categoryName, slug },
        { onConflict: "user_id,slug" },
      )
      .select("id, name, slug")
      .single();

    if (catErr || !cat) {
      return new Response(JSON.stringify({ ok: false, error: `category upsert failed: ${catErr?.message ?? "unknown"}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4) note 업데이트 (폴더 연결 + status done)
    const { error: updErr } = await supabase
      .from("notes")
      .update({ category_id: cat.id, status: "done" })
      .eq("id", note.id);

    if (updErr) {
      return new Response(JSON.stringify({ ok: false, error: `note update failed: ${updErr.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 5) 응답
    return new Response(
      JSON.stringify({
        ok: true,
        note_id: note.id,
        category: cat,
        ...result,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
