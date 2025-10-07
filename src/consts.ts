import type { Site, Metadata, Socials } from "@types";

export const SITE: Site = {
  NAME: "Lê Quang Phú",
  EMAIL: "quangphu.le512@gmail.com",
  NUM_POSTS_ON_HOMEPAGE: 2,
  NUM_WORKS_ON_HOMEPAGE: 2,
  NUM_PROJECTS_ON_HOMEPAGE: 2,
};

export const HOME: Metadata = {
  TITLE: "Lê Quang Phú – Data Analyst & Finance Professional",
  DESCRIPTION: "Portfolio and resume of Lê Quang Phú, data analyst, open-source contributor, and finance professional specialized in blockchain, data engineering, and financial strategy.",
  ABOUT: [
    "I am a skilled data analyst, open-source contributor, and finance professional with over eight years of experience in data engineering, blockchain data decoding, and financial strategy. Expert in developing advanced ETL pipelines, including a cryptocurrency protocol valuation tool analyzing over 5,000 protocols using data from DeFiLlama and CoinMarketCap APIs, complemented by a React dashboard for real-time financial insights.",
    "Proficient in decoding logs and traces of EVM-based chains, leveraging tools such as SQL, Python, dbt, Airflow, Superset, and platforms like Dune.com and Google Cloud Platform to process large-scale blockchain data and drive operational efficiency. Successfully led teams, secured grants, and optimized business processes, with a strong foundation in financial planning and analysis.",
    "Committed to delivering innovative, data-driven solutions in dynamic, high-impact environments. Holds CFA Level I and data science certifications, complemented by a Bachelor's in Corporate Finance."
  ]
};

export const BLOG: Metadata = {
  TITLE: "Blog",
  DESCRIPTION: "A collection of articles on topics I am passionate about.",
};

export const WORK: Metadata = {
  TITLE: "Work",
  DESCRIPTION: "Where I have worked and what I have done.",
};

export const PROJECTS: Metadata = {
  TITLE: "Projects",
  DESCRIPTION: "A collection of my projects, with links to repositories and demos.",
};

export const SOCIALS: Socials = [
  {
    NAME: "x (twitter)",
    HREF: "https://x.com/iamlequangphu",
  },
  {
    NAME: "github",
    HREF: "https://github.com/lequangphu",
  },
  {
    NAME: "linkedin",
    HREF: "https://linkedin.com/in/lequangphu",
  }
];
