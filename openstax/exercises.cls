%% exercises.cls
%% Shared look-and-feel for OpenStax exercise-import documents (openstax/).
%%
%% Content files should do:
%%   \documentclass{exercises}
%%   \title{...}            % required -- e.g. the book title
%%   \subtitle{...}         % optional -- e.g. "Section 5.1 Exercises: Sequences"
%%   \sourceurl{...}        % required -- the OpenStax page URL
%%   \begin{document}
%%   \maketitle
%%   ...
%%   \end{document}
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{exercises}[2026/09/08 Shared OpenStax exercise-import document class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[11pt]{article}

% ---------- Fonts & typography ----------
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{microtype}
\RequirePackage{textcomp}
\RequirePackage{amsmath,amssymb,amsfonts}
\RequirePackage{enumitem}
\setlist{itemsep=2pt,topsep=4pt}

\setlength{\parskip}{5pt}
\setlength{\parindent}{0pt}

% ---------- Page geometry ----------
\RequirePackage[margin=1in]{geometry}

% ---------- Title block ----------
\newcommand{\subtitle}[1]{\gdef\@subtitle{#1}}
\gdef\@subtitle{}

\newcommand{\sourceurl}[1]{\gdef\@sourceurl{#1}}
\gdef\@sourceurl{}

% ---------- Source / license notice ----------
% Every openstax/ document reproduces OpenStax content under CC BY 4.0,
% which requires attribution -- this prints the source URL and license line
% automatically instead of leaving each generated file to spell it out.
\newcommand{\sourcenotice}{%
  \ifx\@sourceurl\@empty\else
    \noindent Source:
    % \underline/ulem's \uline can't break across the line wrap a long source
    % URL needs, so the underline is drawn by the PDF viewer instead, via a
    % link border in "underline" style, scoped to just this link so other
    % links (e.g. the CC BY link below) stay borderless per \hypersetup{hidelinks}.
    {\hypersetup{hidelinks=false,colorlinks=false,urlbordercolor=black,pdfborder={0 0 1},pdfborderstyle={/S/U/W 1}}\url{\@sourceurl}}.
    Exercises reproduced from OpenStax,
    licensed under \href{https://creativecommons.org/licenses/by/4.0/}{CC BY 4.0}.
    \par\smallskip
  \fi
}

% ---------- Conversion-accuracy notice ----------
% Unlike essays/flashcards, the *content* here isn't LLM-authored -- it's
% OpenStax's own text -- but the LaTeX (especially the math) was produced by
% an automated MathML-to-LaTeX conversion (openstax/extract-exercises.py)
% that has already needed several rounds of bug fixes. Flag that plainly
% rather than implying these transcriptions are guaranteed faithful.
\newcommand{\conversionnotice}{%
  \begin{center}
    \small\itshape
    This document was converted programmatically from OpenStax content;
    formulas were translated automatically from MathML and may contain
    conversion errors --- verify against the source before relying on them.
  \end{center}
  \vspace{6pt}
}

\renewcommand{\maketitle}{%
  \begin{center}
    {\Huge\bfseries\@title\par}\vspace{12pt}
    \ifx\@subtitle\@empty\else
      {\large\@subtitle\par}\vspace{14pt}
    \fi
    \ifx\@author\@empty\else
      {\normalsize\@author\par}\vspace{8pt}
    \fi
    \ifx\@date\@empty\else
      {\normalsize\@date\par}\vspace{8pt}
    \fi
  \end{center}
  \vspace{6pt}
  \sourcenotice
  \conversionnotice
}

% ---------- Technology-required marker ----------
% OpenStax prefixes exercises that need a calculator/CAS with a literal
% "[T]" -- a leading "[" right after \item would otherwise be parsed as
% \item's optional relabeling argument (silently replacing the item number
% with the label "T"), so the generator can't emit it as plain text. \
% forces the space that would otherwise be swallowed as part of reading this
% control word's name, so the marker keeps its normal gap before the item
% text that follows.
\newcommand{\techrequired}{[T]\ }

% ---------- Links (xurl before hyperref, so \url line-breaks long URLs; loaded last per hyperref convention) ----------
\RequirePackage{xcolor}
\RequirePackage{xurl}
\RequirePackage{hyperref}
\hypersetup{
  hidelinks,
  pdfstartview=Fit,
  breaklinks=true,
}
\urlstyle{same}
