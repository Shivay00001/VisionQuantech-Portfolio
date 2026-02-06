import OpenAI from 'openai';
import type { AIOptions } from '@you-pdf/core';

export class AIEngine {
  private openai: OpenAI;

  constructor(apiKey: string) {
    this.openai = new OpenAI({ apiKey });
  }

  async summarize(text: string, options: AIOptions = {}): Promise<string> {
    const length = options.length || 'medium';
    const format = options.format || 'paragraph';
    
    let lengthInstruction = '';
    switch (length) {
      case 'short':
        lengthInstruction = 'in 2-3 sentences';
        break;
      case 'medium':
        lengthInstruction = 'in 1-2 paragraphs';
        break;
      case 'long':
        lengthInstruction = 'in 3-4 detailed paragraphs';
        break;
    }

    let formatInstruction = '';
    if (format === 'bullets') {
      formatInstruction = 'Format the summary as bullet points.';
    }

    const prompt = `Summarize the following text ${lengthInstruction}. ${formatInstruction}

Text:
${text}

Summary:`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: options.temperature || 0.3,
      max_tokens: 1000,
    });

    return response.choices[0].message.content || '';
  }

  async translate(text: string, targetLang: string, options: AIOptions = {}): Promise<string> {
    const prompt = `Translate the following text to ${targetLang}. Maintain the original tone and style.

Text:
${text}

Translation:`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: options.temperature || 0.3,
      max_tokens: 2000,
    });

    return response.choices[0].message.content || '';
  }

  async chatWithPDF(text: string, question: string, options: AIOptions = {}): Promise<string> {
    const prompt = `You are a helpful assistant analyzing a document. Based on the following document content, answer the user's question accurately and concisely.

Document Content:
${text.substring(0, 10000)}

User Question: ${question}

Answer:`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: options.temperature || 0.5,
      max_tokens: 1000,
    });

    return response.choices[0].message.content || '';
  }

  async extractKeywords(text: string): Promise<string[]> {
    const prompt = `Extract the 10 most important keywords or key phrases from the following text. Return them as a comma-separated list.

Text:
${text.substring(0, 5000)}

Keywords:`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 200,
    });

    const content = response.choices[0].message.content || '';
    return content.split(',').map(k => k.trim()).filter(Boolean);
  }

  async analyzeResume(text: string, jobDescription?: string): Promise<any> {
    const prompt = jobDescription
      ? `Analyze the following resume against the job description. Provide:
1. Match score (0-100)
2. Key skills found
3. Missing skills
4. Strengths
5. Suggestions for improvement

Job Description:
${jobDescription}

Resume:
${text}

Provide the analysis in JSON format with keys: matchScore, skills, missingSkills, strengths, suggestions`
      : `Analyze the following resume and extract:
1. Contact information
2. Skills
3. Experience summary
4. Education
5. Key strengths

Resume:
${text}

Provide the analysis in JSON format with keys: contact, skills, experience, education, strengths`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a professional resume analyzer. Always respond with valid JSON only.',
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 1500,
    });

    const content = response.choices[0].message.content || '{}';
    
    try {
      return JSON.parse(content);
    } catch {
      return { error: 'Failed to parse analysis', raw: content };
    }
  }

  async bookNotes(text: string): Promise<string> {
    const prompt = `Create comprehensive study notes from the following book content. Include:
- Main themes and concepts
- Key points and arguments
- Important quotes
- Chapter summaries
- Takeaways

Book Content:
${text.substring(0, 15000)}

Study Notes:`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.4,
      max_tokens: 2000,
    });

    return response.choices[0].message.content || '';
  }

  async quizFromText(text: string, numQuestions: number = 10): Promise<any> {
    const prompt = `Create ${numQuestions} multiple-choice questions based on the following text. Each question should have 4 options with one correct answer.

Text:
${text.substring(0, 10000)}

Return the quiz in JSON format as an array of objects with keys: question, options (array of 4 strings), correctAnswer (index 0-3), explanation`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are an educational content creator. Always respond with valid JSON only.',
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.5,
      max_tokens: 2000,
    });

    const content = response.choices[0].message.content || '[]';
    
    try {
      return JSON.parse(content);
    } catch {
      return { error: 'Failed to parse quiz', raw: content };
    }
  }

  async generateFlashcards(text: string, numCards: number = 20): Promise<any> {
    const prompt = `Create ${numCards} flashcards from the following text. Each flashcard should have a front (question/term) and back (answer/definition).

Text:
${text.substring(0, 10000)}

Return the flashcards in JSON format as an array of objects with keys: front, back`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are an educational content creator. Always respond with valid JSON only.',
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.4,
      max_tokens: 2000,
    });

    const content = response.choices[0].message.content || '[]';
    
    try {
      return JSON.parse(content);
    } catch {
      return { error: 'Failed to parse flashcards', raw: content };
    }
  }

  async parseInvoice(text: string): Promise<any> {
    const prompt = `Extract invoice information from the following text:

Text:
${text}

Return JSON with keys: invoiceNumber, date, dueDate, vendor, customer, items (array with description, quantity, price), subtotal, tax, total, currency`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a document parser. Always respond with valid JSON only.',
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.1,
      max_tokens: 1000,
    });

    const content = response.choices[0].message.content || '{}';
    
    try {
      return JSON.parse(content);
    } catch {
      return { error: 'Failed to parse invoice', raw: content };
    }
  }

  async extractContract(text: string): Promise<any> {
    const prompt = `Extract key information from the following contract:

Contract Text:
${text}

Return JSON with keys: parties (array), effectiveDate, expirationDate, terms (array of main terms), obligations (object with keys for each party), signatures, keyPoints`;

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a legal document analyzer. Always respond with valid JSON only.',
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.1,
      max_tokens: 1500,
    });

    const content = response.choices[0].message.content || '{}';
    
    try {
      return JSON.parse(content);
    } catch {
      return { error: 'Failed to parse contract', raw: content };
    }
  }
}