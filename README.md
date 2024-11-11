# The Art of Positivity in Drawing: Unveiling the Impact of Positive Mood States on Visual Creativity via Deep Learning

This respostory contains proposal, presentation, and final paper for my MA thesis at UChicago. It extends from the [repository](https://github.com/UC-MACS-30200/course-project-cty20010831) for MACS 30200 course I took during 2024 spring quarter, when I  wrote the proposal for this research project.

## Github Repo Navigation

    .
    ├── drawio/               # Drawio flowcharts and diagrams
    ├── Proposal_sections/    # Sections (components) of final proposal
    ├── sample_drawing_AuDrA  # Sample drawings to test the AuDrA model
    ├── screenshots/          # Screenshots for better concept/framework explanation for presentation
    ├── CITATIONS.cff         # Let others know how to cite this repository
    ├── Presentation.pptx     # Powerpoint for final presentation
    ├── Presentation.tex      # Latex code for beamer presentation
    ├── Proposal.tex          # Latex code for final proposal
    ├── Proposal.pdf          # Pdf file for final proposal
    ├── README.md             # README file
    └── references.bib        # Bibliography database file

## Study Description
### Introduction
This project explores the intricate relationship between mood states and creativity, specifically focusing on how mood activation levels such as happiness and calmness influence creative outputs. By employing advanced deep learning techniques, experimental tasks like the incompleteness drawing task, and narrative analysis methods like Divergent Semantic Integration (DSI), this study aims to quantitatively dissect the creative process into measurable aspects of flexibility and originality.

### Definitions of Key Concepts
- **Mood:** Mood is characterized as diffuse affective states that are not targeted at any particular object. Unlike emotions, which are acute and directed responses, moods are diffuse
and enduring affective states that subtly color our psychological landscape. Mood significantly affects cognition by influencing what we think and the efficiency of our cognitive processes.
- **Flexibility Aspect of Creativity:** In the context of creativity, flexibility refers to the ability to generate diverse solutions to a problem or adapt one’s thinking to encompass a wide range of possible answers. It involves switching between different thought processes and perspectives, crucial for innovative thinking.
- **Originality Aspect of Creativity:** Originality in creativity is defined as the uniqueness and novelty of the ideas or products generated. It reflects an output's deviation from the norm or standard conventions, showcasing unique or unprecedented solutions.

### Theoretical Frameworks
#### Dual Pathway to Creativity Model (De Dreu et al., 2008)
This model suggests that creativity is influenced by two primary pathways: cognitive flexibility and cognitive persistence. Cognitive flexibility facilitates the exploration of a wide array of ideas and is often enhanced by positive mood states, whereas cognitive persistence involves a deeper, more focused engagement on a narrower set of ideas, typically supported by more negative mood states.

#### Multi-Trial Creative Ideation (MTCI) Framework
Developed by Barbot (2018), the MTCI framework is designed to assess the dynamic process of creative ideation over multiple trials. It emphasizes capturing the fluctuations in creative thinking across different stages of the ideation process, allowing for a detailed examination of how creative ideas evolve and culminate into final products.

### Research Questions
1. How do varying levels of positive mood activation affect cognitive flexibility during the creative ideation process?
2. Does cognitive flexibility mediate the relationship between positive mood and the originality of creative outputs?

### Overview of Research Design
This study aims to advance the debate on the mood-creativity connection by **introducing a novel task-measurement combination**, which leverages both the versatility of drawing tasks to uncover the cognitive underpinnings of creativity and employing state-of-the-art artificial intelligence techniques. This study aims to capture the nuanced effects of mood on creative processes and, more specifically, the (potential) building effects of positive mood states on thought-action repertoires. By distinguishing positive mood states varying on the activation dimension—happiness (high activation) and calmness (low activation), this study seeks to scrutinize the hypothesized flexibility pathway in the dual pathway to creativity model. 

Following the  MTCI framework, this proposed study will adopt the **incomplete shape drawing task** and **narrative about creative ideation processes** to not only record the final creative output, but also track the dynamics of creative thinking that leads to the final completed drawings. Specifically, this study will measure flexibility using the **Compositional Stroke Embedding (CoSE) model**, which utilizes a Gaussian Mixture Model (GMM) to predict potential strokes in the incompleteness shape drawing task. This approach assesses the uncertainty and variability between possible strokes, employing metrics such as **entropy and Bhattacharyya distance** to capture the dynamic range of creative options. Complementing this, flexibility will be further evaluated through **Divergent Semantic Integration (DSI)**, which employs BERT-generated embeddings to analyze how participants integrate divergent ideas into their narratives. Meanwhile, originality will be evaluated using the **Automated Drawing Assessment (AuDrA) model** trained with human ratings on the same incompleteness shape drawing task (see the figure of overall research design below). 

Together, this proposed study not only aims to elucidate mood-creativity linkage, but also underscores the transformative potential of integrating artificial intelligence into the study of complex human cognitive processes.

## Acknoledgement
This research project could not be possible without the support of my advisor [Akram Bakkour](https://psychology.uchicago.edu/directory/Akram-Bakkour) and my preceptor [Sabrina Nardin](https://macss.uchicago.edu/directory/Sabrina-Nardin), whose valuable feedback has pushed me forward in refining my research questions, enhancing methodological rigor, and navigating complex data analysis techniques. Their guidance and insights have been instrumental in shaping the direction of this project, from initial conceptualization to execution, and have inspired me to continuously strive for clarity, precision, and depth in my work.

I would also like to thank Dan (my classmate of MACS 30200 course) and Dr. Pedro (instructor of MACS 30200 course) for their constructive feedback for my first draft of proposal. Dan’s insights helped me address critical areas like clarifying the creativity assessment literature gap, correcting citations, and ensuring conceptual consistency, while his suggestion to include the circumplex model enriched the mood explanation. Dr. Pedro’s advice strengthened my literature foundation and encouraged me to articulate the significance of my integrative, automated approach to creativity assessment. Their feedback has greatly enhanced the clarity, rigor, and impact of my research.