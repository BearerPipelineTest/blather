module Blather
class Stanza

  # Exchanging messages is a basic use of XMPP and occurs when a user generates a message stanza
  # that is addressed to another entity. The sender's server is responsible for delivering the
  # message to the intended recipient (if the recipient is on the same local server) or for routing
  # the message to the recipient's server (if the recipient is on a remote server). Thus a message
  # stanza is used to "push" information to another entity.
  #
  # == To Attribute
  #
  # An instant messaging client specifies an intended recipient for a message by providing the JID
  # of an entity other than the sender in the +to+ attribute of the Message stanza. If the message
  # is being sent outside the context of any existing chat session or received message, the value
  # of the +to+ address SHOULD be of the form "user@domain" rather than of the form "user@domain/resource".
  #
  #   msg = Message.new 'user@domain.tld/resource'
  #   msg.to == 'user@domain.tld/resource'
  #
  #   msg.to = 'another-user@some-domain.tld/resource'
  #   msg.to == 'another-user@some-domain.tld/resource'
  #
  # The +to+ attribute on a Message stanza works like any regular ruby object attribute
  #
  # == Type Attribute
  #
  # Common uses of the message stanza in instant messaging applications include: single messages;
  # messages sent in the context of a one-to-one chat session; messages sent in the context of a
  # multi-user chat room; alerts, notifications, or other information to which no reply is expected;
  # and errors. These uses are differentiated via the +type+ attribute. If included, the +type+
  # attribute MUST have one of the following values:
  #
  # * +:chat+ -- The message is sent in the context of a one-to-one chat session. Typically a receiving 
  #   client will present message of type +chat+ in an interface that enables one-to-one chat between
  #   the two parties, including an appropriate conversation history.
  # * +:error+ -- The message is generated by an entity that experiences an error in processing a message
  #   received from another entity. A client that receives a message of type +error+ SHOULD present an
  #   appropriate interface informing the sender of the nature of the error.
  # * +:groupchat+ -- The message is sent in the context of a multi-user chat environment (similar to that
  #   of [IRC]). Typically a receiving client will present a message of type +groupchat+ in an interface
  #   that enables many-to-many chat between the parties, including a roster of parties in the chatroom
  #   and an appropriate conversation history.
  # * +:headline+ -- The message provides an alert, a notification, or other information to which no reply
  #   is expected (e.g., news headlines, sports updates, near-real-time market data, and syndicated content).
  #   Because no reply to the message is expected, typically a receiving client will present a message of
  #   type "headline" in an interface that appropriately differentiates the message from standalone messages,
  #   chat messages, or groupchat messages (e.g., by not providing the recipient with the ability to reply).
  # * +:normal+ -- The message is a standalone message that is sent outside the context of a one-to-one
  #   conversation or groupchat, and to which it is expected that the recipient will reply. Typically a receiving
  #   client will present a message of type +normal+ in an interface that enables the recipient to reply, but
  #   without a conversation history. The default value of the +type+ attribute is +normal+.
  #
  # Blather provides a helper for each possible type:
  #
  #   Message#chat?
  #   Message#error?
  #   Message#groupchat?
  #   Message#headline?
  #   Message#normal?
  #
  # Blather treats the +type+ attribute like a normal ruby object attribute providing a getter and setter.
  # The default +type+ is +chat+.
  #
  #   msg = Message.new
  #   msg.type              # => :chat
  #   msg.chat?             # => true
  #   msg.type = :normal
  #   msg.normal?           # => true
  #   msg.chat?             # => false
  #
  #   msg.type = :invalid   # => RuntimeError
  #
  # == Body Element
  #
  # The +body+ element contains human-readable XML character data that specifies the textual contents of the message;
  # this child element is normally included but is optional.
  #
  # Blather provides an attribute-like syntax for Message +body+ elements.
  #
  #   msg = Message.new 'user@domain.tld', 'message body'
  #   msg.body  # => 'message body'
  #
  #   msg.body = 'other message'
  #   msg.body  # => 'other message'
  #
  # == Subject Element
  #
  # The +subject+ element contains human-readable XML character data that specifies the topic of the message.
  #
  # Blather provides an attribute-like syntax for Message +subject+ elements.
  #
  #   msg = Message.new 'user@domain.tld', 'message subject'
  #   msg.subject  # => 'message subject'
  #
  #   msg.subject = 'other subject'
  #   msg.subject  # => 'other subject'
  #
  # == Thread Element
  #
  # The primary use of the XMPP +thread+ element is to uniquely identify a conversation thread or "chat session"
  # between two entities instantiated by Message stanzas of type +chat+. However, the XMPP thread element can
  # also be used to uniquely identify an analogous thread between two entities instantiated by Message stanzas
  # of type +headline+ or +normal+, or among multiple entities in the context of a multi-user chat room instantiated
  # by Message stanzas of type +groupchat+. It MAY also be used for Message stanzas not related to a human
  # conversation, such as a game session or an interaction between plugins. The +thread+ element is not used to
  # identify individual messages, only conversations or messagingg sessions. The inclusion of the +thread+ element
  # is optional. 
  #
  # The value of the +thread+ element is not human-readable and MUST be treated as opaque by entities; no semantic
  # meaning can be derived from it, and only exact comparisons can be made against it. The value of the +thread+
  # element MUST be a universally unique identifier (UUID) as described in [UUID].
  #
  # The +thread+ element MAY possess a 'parent' attribute that identifies another thread of which the current
  # thread is an offshoot or child; the value of the 'parent' must conform to the syntax of the +thread+ element itself.
  #
  # Blather provides an attribute-like syntax for Message +thread+ elements.
  # 
  #   msg = Message.new
  #   msg.thread = '12345'
  #   msg.thread                                  # => '12345'
  #
  # Parent threads can be set using a hash:
  #
  #   msg.thread = {'parent-id' => 'thread-id'}
  #   msg.thread                                  # => 'thread-id'
  #   msg.parent_thread                           # => 'parent-id'
  class Message < Stanza
    VALID_TYPES = [:chat, :error, :groupchat, :headline, :normal] # :nodoc:

    register :message

    def self.import(node) # :nodoc:
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }

      if klass && klass != self
        klass.import(node)
      else
        new(node[:type]).inherit(node)
      end
    end

    def self.new(to = nil, body = nil, type = :chat)
      node = super :message
      node.to = to
      node.type = type
      node.body = body
      node
    end

    attribute_helpers_for :type, VALID_TYPES

    def type=(type) # :nodoc:
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end

    content_attr_accessor :body
    content_attr_accessor :subject

    content_attr_reader :thread

    def parent_thread # :nodoc:
      n = find_first('thread')
      n[:parent] if n
    end

    def thread=(thread) # :nodoc:
      parent, thread = thread.to_a.flatten if thread.is_a?(Hash)
      set_content_for :thread, thread
      find_first('thread')[:parent] = parent
    end
  end

end #Stanza
end