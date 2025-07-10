const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const cors = require('cors')({ origin: true });

admin.initializeApp();

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

// Generate content (resume, cover letter, interview questions)
exports.generateContent = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { type, prompt, template, company, position, resumeContent } = data;
  
  try {
    let response;
    
    switch (type) {
      case 'resume':
        response = await generateResume(prompt, template);
        break;
        
      case 'coverLetter':
        response = await generateCoverLetter(company, position, resumeContent, template);
        break;
        
      case 'interviewQuestions':
        response = await generateInterviewQuestions(position, company);
        break;
        
      case 'linkedinReview':
        response = await reviewLinkedInProfile(data.profileURL);
        break;
        
      default:
        throw new functions.https.HttpsError('invalid-argument', 'Invalid content type');
    }
    
    return response;
  } catch (error) {
    console.error('Error generating content:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

async function generateResume(prompt, template) {
  const systemPrompt = `You are a professional resume writer. Generate a structured resume based on the user's information. 
  
Template Style: ${template}

Format the response as a structured JSON with the following sections:
- personalInfo: { fullName, email, phone, location, linkedin, website, summary }
- experience: [{ company, position, startDate, endDate, isCurrent, description, achievements }]
- education: [{ institution, degree, field, startDate, endDate, gpa, relevantCourses }]
- skills: [{ name, level, category }]
- projects: [{ name, description, technologies, url, startDate, endDate }]
- certifications: [{ name, issuer, date, expiryDate, url }]
- languages: [{ name, proficiency }]

Make the resume professional, concise, and tailored to the user's background.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: prompt }
    ],
    temperature: 0.7,
    max_tokens: 2000
  });

  const content = completion.choices[0].message.content;
  
  try {
    // Try to parse as JSON, if not, return as plain text
    const parsed = JSON.parse(content);
    return { content: parsed };
  } catch {
    return { content: content };
  }
}

async function generateCoverLetter(company, position, resumeContent, template) {
  const systemPrompt = `You are a professional cover letter writer. Generate a compelling cover letter for the specified position and company.

Template Style: ${template}

Company: ${company}
Position: ${position}

Resume Summary: ${resumeContent}

Write a professional cover letter that:
1. Addresses the hiring manager
2. Explains why you're interested in the position
3. Highlights relevant experience and skills
4. Shows enthusiasm for the company
5. Includes a call to action
6. Is 250-400 words

Make it personalized, professional, and compelling.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: systemPrompt }
    ],
    temperature: 0.7,
    max_tokens: 1000
  });

  return { content: completion.choices[0].message.content };
}

async function generateInterviewQuestions(position, company) {
  const systemPrompt = `Generate 10 relevant interview questions for the position of ${position} at ${company}.

Include a mix of:
- Technical questions (if applicable)
- Behavioral questions
- Company-specific questions
- Role-specific questions

Format as a JSON array of strings.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: systemPrompt }
    ],
    temperature: 0.7,
    max_tokens: 1000
  });

  const content = completion.choices[0].message.content;
  
  try {
    const questions = JSON.parse(content);
    return { questions: Array.isArray(questions) ? questions : [content] };
  } catch {
    // If parsing fails, split by newlines and clean up
    const questions = content.split('\n')
      .map(q => q.trim())
      .filter(q => q.length > 0 && !q.startsWith('-') && !q.startsWith('*'))
      .slice(0, 10);
    
    return { questions };
  }
}

async function reviewLinkedInProfile(profileURL) {
  const systemPrompt = `You are a professional LinkedIn profile reviewer. Analyze the LinkedIn profile at ${profileURL} and provide constructive feedback.

Provide feedback on:
1. Profile completeness
2. Professional summary
3. Experience descriptions
4. Skills and endorsements
5. Recommendations
6. Overall branding

Format your response as a structured review with specific recommendations for improvement.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: systemPrompt }
    ],
    temperature: 0.7,
    max_tokens: 1500
  });

  return { review: completion.choices[0].message.content };
}

// HTTP endpoint for webhook integrations
exports.webhook = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      // Verify webhook signature if needed
      const { type, data } = req.body;
      
      switch (type) {
        case 'resume_generation':
          const resumeResult = await generateResume(data.prompt, data.template);
          res.json(resumeResult);
          break;
          
        case 'cover_letter_generation':
          const coverLetterResult = await generateCoverLetter(
            data.company, 
            data.position, 
            data.resumeContent, 
            data.template
          );
          res.json(coverLetterResult);
          break;
          
        default:
          res.status(400).json({ error: 'Invalid webhook type' });
      }
    } catch (error) {
      console.error('Webhook error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
});

// Scheduled function for data cleanup (optional)
exports.cleanupOldData = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90); // 90 days ago
    
    // Clean up old PDF files in Storage
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({
      prefix: 'pdfs/',
      maxResults: 1000
    });
    
    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const createdAt = new Date(metadata.timeCreated);
      
      if (createdAt < cutoffDate) {
        await file.delete();
        console.log(`Deleted old file: ${file.name}`);
      }
    }
    
    console.log('Data cleanup completed');
  } catch (error) {
    console.error('Cleanup error:', error);
  }
});

// Analytics function for tracking usage
exports.trackUsage = functions.analytics.event('content_generated').onLog(async (event) => {
  try {
    const { user_id, event_params } = event;
    const contentType = event_params.find(p => p.key === 'content_type')?.value?.string_value;
    
    // Log usage to Firestore for analytics
    await admin.firestore().collection('usage_analytics').add({
      userId: user_id,
      contentType: contentType,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      event: 'content_generated'
    });
    
    console.log(`Usage tracked: ${contentType} for user ${user_id}`);
  } catch (error) {
    console.error('Usage tracking error:', error);
  }
}); 